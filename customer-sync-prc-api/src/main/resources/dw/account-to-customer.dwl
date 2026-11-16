%dw 2.0
import * from modules::Lookups
output application/json skipNullOn="everywhere"
// Salesforce Account (vars.account) -> finance customer.
var account = vars.account
---
{
  name:        account.name,
  abn:         digitsOnly(account.abn),
  email:       account.email,
  phone:       account.phone,
  addressLine: account.billingStreet,
  suburb:      account.billingCity,
  state:       toStateCode(account.billingState),
  postcode:    account.billingPostalCode,
  status:      toFinanceStatus(account.status),
  creditLimit: account.creditLimit
}
