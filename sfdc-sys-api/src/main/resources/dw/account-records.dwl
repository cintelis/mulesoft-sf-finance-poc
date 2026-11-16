%dw 2.0
output application/java
// API accounts -> Salesforce Account records, keyed on the finance customer code.
---
payload.items map (account) -> {
  Finance_Customer_Code__c: account.financeCustomerCode,
  Name: account.name,
  (ABN__c:            account.abn)               if (account.abn != null),
  (Accounts_Email__c: account.email)             if (account.email != null),
  (Phone:             account.phone)             if (account.phone != null),
  (BillingStreet:     account.billingStreet)     if (account.billingStreet != null),
  (BillingCity:       account.billingCity)       if (account.billingCity != null),
  (BillingState:      account.billingState)      if (account.billingState != null),
  (BillingPostalCode: account.billingPostalCode) if (account.billingPostalCode != null),
  (BillingCountry:    account.billingCountry)    if (account.billingCountry != null),
  (Account_Status__c: account.status)            if (account.status != null),
  (Credit_Limit__c:   account.creditLimit)       if (account.creditLimit != null)
}
