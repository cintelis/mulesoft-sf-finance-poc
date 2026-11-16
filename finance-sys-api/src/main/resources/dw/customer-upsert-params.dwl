%dw 2.0
import isBlank from dw::core::Strings
output application/java

// Request body -> upsert_customer input parameters.
// Blank strings become NULL so they do not overwrite data with whitespace.
fun clean(value) =
  if (value == null or isBlank(value as String)) null else trim(value as String)

fun digitsOnly(value) = clean((value default "") replace /\D/ with "")
---
{
  p_sf_account_id: vars.sfAccountId,
  p_customer_name: clean(payload.name),
  p_abn:           digitsOnly(payload.abn),
  p_email:         if (clean(payload.email) != null) lower(clean(payload.email)) else null,
  p_phone:         clean(payload.phone),
  p_address_line:  clean(payload.addressLine),
  p_suburb:        clean(payload.suburb),
  p_state_code:    clean(payload.state),
  p_postcode:      clean(payload.postcode),
  p_status:        clean(payload.status),
  p_credit_limit:  payload.creditLimit
}
