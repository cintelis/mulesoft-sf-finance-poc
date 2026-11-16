%dw 2.0
output application/json
fun toAccount(row) = {
  id: row.Id,
  name: row.Name,
  abn: row.ABN__c,
  email: row.Accounts_Email__c,
  phone: row.Phone,
  billingStreet: row.BillingStreet,
  billingCity: row.BillingCity,
  billingState: row.BillingState,
  billingPostalCode: row.BillingPostalCode,
  billingCountry: row.BillingCountry,
  status: row.Account_Status__c,
  creditLimit: if (row.Credit_Limit__c == null) null else (row.Credit_Limit__c as Number),
  financeCustomerCode: row.Finance_Customer_Code__c,
  lastModified: row.LastModifiedDate
}
var rows = payload default []
---
{
  count: sizeOf(rows),
  items: rows map (row) -> toAccount(row)
}
