%dw 2.0
output application/json
var rows = payload default []
---
{
  count: sizeOf(rows),
  // Rows arrive oldest change first, so the last row carries the new watermark.
  // An empty page hands the caller's watermark back unchanged.
  nextWatermark: rows[-1].LAST_MODIFIED default vars.modifiedSince,
  items: rows map (row) -> {
    invoiceNumber: row.INVOICE_NUMBER,
    customerCode:  row.CUSTOMER_CODE,
    sfAccountId:   row.SF_ACCOUNT_ID,
    invoiceDate:   row.INVOICE_DATE,
    dueDate:       row.DUE_DATE,
    amountExGst:   row.AMOUNT_EX_GST,
    gstAmount:     row.GST_AMOUNT,
    totalAmount:   row.TOTAL_AMOUNT,
    amountPaid:    row.AMOUNT_PAID,
    balance:       row.TOTAL_AMOUNT - row.AMOUNT_PAID,
    currency:      row.CURRENCY_CODE,
    status:        row.STATUS,
    description:   row.DESCRIPTION,
    lastModified:  row.LAST_MODIFIED
  }
}
