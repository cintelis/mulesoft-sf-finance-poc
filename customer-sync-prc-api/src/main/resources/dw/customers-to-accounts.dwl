%dw 2.0
import * from modules::Lookups
output application/json skipNullOn="everywhere"
// Finance customers (vars.customers) -> Salesforce Account upserts, keyed on the
// finance customer code. Used by the historical migration.
---
{
  items: vars.customers map (customer) -> {
    financeCustomerCode: customer.customerCode,
    name:              customer.name,
    abn:               customer.abn,
    email:             customer.email,
    phone:             customer.phone,
    billingStreet:     customer.addressLine,
    billingCity:       customer.suburb,
    billingState:      toStateName(customer.state),
    billingPostalCode: customer.postcode,
    billingCountry:    if (customer.country == "AU") "Australia" else customer.country,
    status:            financeStatusToAccount[customer.status default ""],
    creditLimit:       customer.creditLimit
  }
}
