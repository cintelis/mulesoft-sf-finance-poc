%dw 2.0
output application/json
var rows = payload default []
---
{
  count: sizeOf(rows),
  items: rows map (row) -> {
    customerId:   row.CUSTOMER_ID,
    customerCode: row.CUSTOMER_CODE,
    sfAccountId:  row.SF_ACCOUNT_ID,
    name:         row.CUSTOMER_NAME,
    abn:          row.ABN,
    email:        row.EMAIL,
    phone:        row.PHONE,
    addressLine:  row.ADDRESS_LINE,
    suburb:       row.SUBURB,
    state:        row.STATE_CODE,
    postcode:     row.POSTCODE,
    country:      row.COUNTRY_CODE,
    status:       row.STATUS,
    creditLimit:  row.CREDIT_LIMIT,
    lastModified: row.LAST_MODIFIED
  }
}
