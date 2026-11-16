%dw 2.0
output application/json
// Salesforce upsert result -> one outcome per record, in request order.
// vars.keys holds the business key of each record that was sent.
var results = payload.items default []
var outcomes = results map (result, index) -> do {
  var ok = result.successful default false
  var fieldErrors = (result.payload.errors default []) map ((e) -> e.message default "Unknown error")
  var otherError = if (ok or result.message == null) [] else [result.message as String]
  ---
  {
    key: vars.keys[index],
    success: ok,
    id: result.payload.id,
    created: result.payload.created default false,
    errors: fieldErrors ++ otherError
  }
}
---
{
  total: sizeOf(outcomes),
  succeeded: sizeOf(outcomes filter ((o) -> o.success)),
  failed: sizeOf(outcomes filter ((o) -> not o.success)),
  results: outcomes
}
