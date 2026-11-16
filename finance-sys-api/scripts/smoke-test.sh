#!/bin/bash
# End-to-end smoke test for finance-sys-api against the Docker database.
#
# Needs: the app running on http://localhost:8081 (or BASE_URL), the finance-db
# container from infra/docker-compose.yml, curl and node.
#
# It only creates rows marked IT and removes them before and after, so the
# seed data is left as it was. Exits non-zero if any check fails.
BASE_URL="${BASE_URL:-http://localhost:8081/api}"
TMP="$(mktemp -d)"
TMP_NODE="$(cygpath -w "$TMP" 2>/dev/null || echo "$TMP")"   # Git Bash on Windows: node needs a Windows path
pass=0; fail=0

sql() {
  MSYS_NO_PATHCONV=1 docker exec -i finance-db bash -c \
    'sqlplus -s -L $APP_USER/$APP_USER_PASSWORD@//localhost/FREEPDB1' <<EOF
SET FEEDBACK OFF HEADING OFF PAGESIZE 0
WHENEVER SQLERROR EXIT SQL.SQLCODE
$1
COMMIT;
EXIT
EOF
}

remove_test_rows() {
  sql "DELETE FROM payments WHERE invoice_id IN (SELECT invoice_id FROM invoices WHERE invoice_number = 'INV-IT-0001');
DELETE FROM invoices WHERE invoice_number = 'INV-IT-0001';
DELETE FROM customers WHERE sf_account_id = '001IT0000000000AAA';
DELETE FROM sync_watermark WHERE sync_name = 'it-sync';"
}

# call METHOD PATH [JSON_BODY] -> sets STATUS and writes the body to $TMP/body.json
call() {
  local args=(-s --max-time 30 -X "$1" "$BASE_URL$2" -H 'X-Correlation-ID: smoke-test' -o "$TMP/body.json" -w '%{http_code}')
  [ -n "$3" ] && args+=(-H 'Content-Type: application/json' -d "$3")
  STATUS="$(curl "${args[@]}")"
}

# field JS_EXPRESSION -> evaluates against the last response body (as `b`)
field() {
  node -e 'const b=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));const v=eval(process.argv[2]);console.log(v===undefined?"undefined":v)' "$TMP_NODE/body.json" "$1" 2>/dev/null
}

check() { # NAME ACTUAL EXPECTED
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "  ok    $1"
  else fail=$((fail+1)); echo "  FAIL  $1: expected [$3], got [$2]"; fi
}

echo "Preparing test rows"
remove_test_rows
sql "INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, description)
SELECT 'INV-IT-0001', customer_id, DATE '2026-11-01', DATE '2026-12-01', 1000, 100, 'Integration test invoice'
  FROM customers WHERE customer_code = 'C001001';"

echo "Health"
call GET /health
check "status 200" "$STATUS" 200
check "database UP" "$(field 'b.database')" UP

echo "Invoices: watermark read"
call GET /invoices
check "status 200" "$STATUS" 200
check "at least the 16 seeded and test invoices" "$(field 'b.count >= 16')" true
check "INV-100004 balance" "$(field 'b.items.find(i => i.invoiceNumber == "INV-100004").balance')" 1530
check "INV-100004 customer" "$(field 'b.items.find(i => i.invoiceNumber == "INV-100004").customerCode')" C001002
check "INV-100004 invoice date" "$(field 'b.items.find(i => i.invoiceNumber == "INV-100004").invoiceDate')" 2026-10-20
WATERMARK="$(field 'b.nextWatermark')"
call GET "/invoices?limit=1"
check "limit=1 returns a short page" "$(field 'b.count >= 1 && b.count < 16')" true
call GET "/invoices?modifiedSince=$WATERMARK"
check "nothing newer than the watermark" "$(field 'b.count')" 0
check "empty page keeps the watermark" "$(field 'b.nextWatermark')" "$WATERMARK"
call GET "/invoices?modifiedSince=yesterday"
check "bad watermark is 400" "$STATUS" 400

echo "Customers: idempotent upsert"
call PUT /customers/001IT0000000000AAA '{"name":"Integration Test Co","abn":"51 824 753 556","email":"IT@Example.com","state":"NSW","postcode":"2000"}'
check "first upsert is 201" "$STATUS" 201
check "first upsert INSERTED" "$(field 'b.action')" INSERTED
CUSTOMER_ID="$(field 'b.customerId')"
call PUT /customers/001IT0000000000AAA '{"name":" Integration Test Co Pty Ltd ","abn":"51 824 753 556","email":"IT@Example.com","state":"NSW","postcode":"2000","status":"ON_HOLD","creditLimit":1500.50}'
check "second upsert is 200" "$STATUS" 200
check "second upsert UPDATED" "$(field 'b.action')" UPDATED
check "same customer row" "$(field 'b.customerId')" "$CUSTOMER_ID"
call GET "/customers?linked=true"
C='b.items.find(c => c.sfAccountId == "001IT0000000000AAA")'
check "name trimmed" "$(field "$C.name")" "Integration Test Co Pty Ltd"
check "ABN digits only" "$(field "$C.abn")" 51824753556
check "email lower case" "$(field "$C.email")" it@example.com
check "status updated" "$(field "$C.status")" ON_HOLD
check "credit limit updated" "$(field "$C.creditLimit")" 1500.5
call GET "/customers?linked=false"
check "unlinked customers are the 8 seeded" "$(field 'b.count')" 8
call PUT /customers/too-short '{"name":"x"}'
check "bad Salesforce ID is 400" "$STATUS" 400

echo "Reconciliation hash"
EXPECTED_HASH="$(printf '%s' 'INTEGRATION TEST CO PTY LTD|51824753556|it@example.com|2000|ON_HOLD' | sha256sum | cut -d' ' -f1)"
call GET /recon/customers
check "database hash equals the hash computed here" "$(field 'b.items.find(c => c.sfAccountId == "001IT0000000000AAA").rowHash')" "$EXPECTED_HASH"

echo "Payments"
PAYMENT='{"paymentRef":"PAY-IT-0001","invoiceNumber":"INV-IT-0001","amount":400.25,"paymentDate":"2026-11-16","method":"BPAY","payerName":"Integration Test","sourceFile":"it.csv"}'
call POST /payments "$PAYMENT"
check "part payment is 201" "$STATUS" 201
check "part payment APPLIED" "$(field 'b.result')" APPLIED
check "invoice PART_PAID" "$(field 'b.invoiceStatus')" PART_PAID
call POST /payments "$PAYMENT"
check "repeat is 200" "$STATUS" 200
check "repeat DUPLICATE" "$(field 'b.result')" DUPLICATE
call POST /payments '{"paymentRef":"PAY-IT-0002","invoiceNumber":"INV-IT-0001","amount":699.75,"paymentDate":"2026-11-16","method":"EFT"}'
check "final payment is 201" "$STATUS" 201
check "invoice PAID" "$(field 'b.invoiceStatus')" PAID
call POST /payments '{"paymentRef":"PAY-IT-0003","invoiceNumber":"INV-999999","amount":500,"paymentDate":"2026-11-17","method":"EFT"}'
check "unknown invoice is 404" "$STATUS" 404
check "unknown invoice code" "$(field 'b.error.code')" INVOICE_NOT_FOUND
check "unknown invoice message" "$(field 'b.error.message')" "Unknown invoice INV-999999"
check "error carries the correlation ID" "$(field 'b.error.correlationId')" smoke-test
call POST /payments '{"paymentRef":"PAY-IT-0004","invoiceNumber":"INV-100014","amount":704,"paymentDate":"2026-11-17","method":"CARD"}'
check "void invoice is 409" "$STATUS" 409
check "void invoice code" "$(field 'b.error.code')" INVOICE_VOID
call POST /payments '{"paymentRef":"PAY-IT-0005","invoiceNumber":"INV-100007","amount":5000,"paymentDate":"2026-11-17","method":"CASH"}'
check "unknown method is 400" "$STATUS" 400
call POST /payments '{"paymentRef":"PAY-IT-0006","invoiceNumber":"INV-100007","amount":-5,"paymentDate":"2026-11-17","method":"EFT"}'
check "negative amount is 400" "$STATUS" 400

echo "Watermarks"
call GET /watermarks/invoice-sync
check "seeded watermark is 200" "$STATUS" 200
call GET /watermarks/it-sync
check "unknown watermark is 404" "$STATUS" 404
call PUT /watermarks/it-sync '{"value":"2026-11-16T01:02:03"}'
check "create watermark is 200" "$STATUS" 200
call PUT /watermarks/it-sync '{"value":"2026-11-16T04:26:19.123456"}'
check "move watermark is 200" "$STATUS" 200
call GET /watermarks/it-sync
check "watermark reads back to the microsecond" "$(field 'b.value')" "2026-11-16T04:26:19.123456"

echo "Customer links"
call PUT /customer-links/NOPE '{"sfAccountId":"001IT0000000000AAB"}'
check "unknown customer is 409" "$STATUS" 409
check "conflict code" "$(field 'b.error.code')" CONFLICT

echo "Routing and headers"
call GET /nothing-here
check "unknown path is 404" "$STATUS" 404
check "unknown path code" "$(field 'b.error.code')" RESOURCE_NOT_FOUND
HEADER="$(curl -s -o /dev/null -D - "$BASE_URL/health" -H 'X-Correlation-ID: smoke-header' | tr -d '\r' | grep -i '^x-correlation-id:' | awk '{print $2}')"
check "correlation ID echoed in the response header" "$HEADER" smoke-header

echo "Removing test rows"
remove_test_rows
rm -rf "$TMP"

echo
echo "Passed: $pass   Failed: $fail"
[ "$fail" -eq 0 ]
