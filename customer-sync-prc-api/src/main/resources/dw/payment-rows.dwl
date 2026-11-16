%dw 2.0
import try from dw::Runtime
import text from modules::Lookups
output application/java
// Legacy payments CSV rows (vars.csvRows) -> validated payments.
// The file uses DD/MM/YYYY dates and amounts such as "1,375.00".
// Every row comes back with its row number, any reasons it was rejected, and,
// when valid, the payment in the finance API's format.
var methods = ["EFT", "BPAY", "CARD", "CHEQUE"]

fun parseAmount(value) = do {
  var cleaned = text(value) replace "," with ""
  ---
  if (cleaned matches /^-?\d+(\.\d{1,2})?$/) (cleaned as Number) else null
}

fun parseDate(value) = do {
  var raw = text(value)
  var parsed = try(() -> (raw as Date {format: "dd/MM/uuuu"}) as String {format: "uuuu-MM-dd"})
  ---
  if ((raw matches /^\d{2}\/\d{2}\/\d{4}$/) and parsed.success) parsed.result else null
}
---
(vars.csvRows default []) map (row, index) -> do {
  var paymentRef = text(row.PAYMENT_REF)
  var invoiceNumber = text(row.INVOICE_NO)
  var amount = parseAmount(row.AMOUNT)
  var paymentDate = parseDate(row.PAY_DATE)
  var method = upper(text(row.METHOD))
  var reasons = [
    ("Payment reference is missing") if (isEmpty(paymentRef)),
    ("Invoice number is missing") if (isEmpty(invoiceNumber)),
    ("Amount is missing") if (isEmpty(text(row.AMOUNT))),
    ("Amount '$(text(row.AMOUNT))' is not a number") if (!isEmpty(text(row.AMOUNT)) and amount == null),
    ("Amount must be above zero") if (amount != null and amount <= 0),
    ("Date '$(text(row.PAY_DATE))' is not DD/MM/YYYY") if (paymentDate == null),
    ("Method '$(text(row.METHOD))' is not one of $(methods joinBy ', ')") if (not (methods contains method))
  ]
  ---
  {
    row: index + 1,
    paymentRef: paymentRef,
    invoiceNumber: invoiceNumber,
    valid: isEmpty(reasons),
    reasons: reasons,
    payment: if (isEmpty(reasons)) {
      paymentRef: paymentRef,
      invoiceNumber: invoiceNumber,
      amount: amount,
      currency: if (isEmpty(text(row.CCY))) "AUD" else upper(text(row.CCY)),
      paymentDate: paymentDate,
      method: method,
      (payerName: text(row.PAYER)) if (!isEmpty(text(row.PAYER))),
      sourceFile: vars.fileName
    } else null
  }
}
