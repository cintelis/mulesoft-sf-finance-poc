%dw 2.0
output application/csv quoteValues=true
// Rows the process API did not apply, as a CSV the finance team can open.
// vars.result is the process API's summary of the file.
---
(vars.result.rows default [])
  filter ((row) -> row.result == "REJECTED" or row.result == "FAILED")
  map (row) -> {
    ROW: row.row,
    PAYMENT_REF: row.paymentRef default "",
    INVOICE_NO: row.invoiceNumber default "",
    RESULT: row.result,
    REASON: row.reason default ""
  }
