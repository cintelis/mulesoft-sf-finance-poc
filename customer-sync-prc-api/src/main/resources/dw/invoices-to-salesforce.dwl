%dw 2.0
import * from modules::Lookups
output application/json skipNullOn="everywhere"
// Finance invoices (vars.page.items) -> Salesforce invoice upserts.
// An invoice whose customer has no Salesforce Account yet is sent without one;
// it is linked on a later run, after the customer is migrated.
---
{
  items: vars.page.items map (invoice) -> {
    invoiceNumber: invoice.invoiceNumber,
    sfAccountId:   invoice.sfAccountId,
    invoiceDate:   invoice.invoiceDate,
    dueDate:       invoice.dueDate,
    amountExGst:   invoice.amountExGst,
    gstAmount:     invoice.gstAmount,
    totalAmount:   invoice.totalAmount,
    amountPaid:    invoice.amountPaid,
    status:        invoiceStatusToSalesforce[invoice.status],
    description:   invoice.description
  }
}
