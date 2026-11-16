%dw 2.0
import customerHash from modules::Recon
output application/json
// Compares finance customers (vars.financeRecon) with Salesforce Accounts
// (vars.accounts) by hash. Only customers linked to Salesforce are in scope on
// the finance side; unlinked ones are reported by the migration, not here.
var financeRows = vars.financeRecon.items default []
var financeById = financeRows groupBy ((row) -> row.sfAccountId)
var salesforceRows = (vars.accounts.items default []) map (account) -> {
  sfAccountId: account.id,
  name: account.name,
  hash: customerHash(account)
}
var salesforceIds = salesforceRows map ((row) -> row.sfAccountId)

fun financeHash(id) = financeById[id][0].rowHash
var matched = salesforceRows filter ((row) -> financeHash(row.sfAccountId) == row.hash)
var mismatched = salesforceRows filter ((row) -> financeHash(row.sfAccountId) != null and financeHash(row.sfAccountId) != row.hash)
var onlyInSalesforce = salesforceRows filter ((row) -> financeHash(row.sfAccountId) == null)
var onlyInFinance = financeRows filter ((row) -> not (salesforceIds contains row.sfAccountId))
---
{
  checkedAt: now() as String {format: "yyyy-MM-dd'T'HH:mm:ssXXX"},
  inSync: isEmpty(mismatched) and isEmpty(onlyInSalesforce) and isEmpty(onlyInFinance),
  salesforceAccounts: sizeOf(salesforceRows),
  financeCustomersLinked: sizeOf(financeRows),
  matchedCount: sizeOf(matched),
  mismatched: mismatched map ((row) -> { sfAccountId: row.sfAccountId, name: row.name, customerCode: financeById[row.sfAccountId][0].customerCode }),
  onlyInSalesforce: onlyInSalesforce map ((row) -> { sfAccountId: row.sfAccountId, name: row.name }),
  onlyInFinance: onlyInFinance map ((row) -> { sfAccountId: row.sfAccountId, customerCode: row.customerCode })
}
