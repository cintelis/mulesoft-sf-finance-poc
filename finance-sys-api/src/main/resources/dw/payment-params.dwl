%dw 2.0
output application/java
// Request body -> apply_payment input parameters.
---
{
  p_payment_ref:    trim(payload.paymentRef),
  p_invoice_number: trim(payload.invoiceNumber),
  p_amount:         payload.amount as Number,
  p_currency_code:  payload.currency default "AUD",
  p_payment_date:   payload.paymentDate as Date,
  p_payment_method: payload.method,
  p_payer_name:     payload.payerName,
  p_source_file:    payload.sourceFile
}
