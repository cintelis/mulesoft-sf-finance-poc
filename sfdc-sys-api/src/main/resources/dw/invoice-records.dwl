%dw 2.0
output application/java
// API invoices -> Salesforce Invoice__c records.
// Only the fields a caller sends are written, so a partial update (for example
// status and amount paid after a payment) leaves the other fields alone.
---
payload.items map (invoice) -> {
  Invoice_Number__c: invoice.invoiceNumber,
  Name: invoice.invoiceNumber,
  (Account__c:       invoice.sfAccountId)         if (invoice.sfAccountId != null),
  (Invoice_Date__c:  invoice.invoiceDate as Date) if (invoice.invoiceDate != null),
  (Due_Date__c:      invoice.dueDate as Date)     if (invoice.dueDate != null),
  (Amount_Ex_GST__c: invoice.amountExGst)         if (invoice.amountExGst != null),
  (GST_Amount__c:    invoice.gstAmount)           if (invoice.gstAmount != null),
  (Total_Amount__c:  invoice.totalAmount)         if (invoice.totalAmount != null),
  (Amount_Paid__c:   invoice.amountPaid)          if (invoice.amountPaid != null),
  (Status__c:        invoice.status)              if (invoice.status != null),
  (Description__c:   invoice.description)         if (invoice.description != null)
}
