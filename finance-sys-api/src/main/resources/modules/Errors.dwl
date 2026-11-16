%dw 2.0

// Maps a Mule error to an HTTP status, a stable error code and a message that
// is safe to show a caller. Used by the global error handler.

var byType = {
  "APIKIT:BAD_REQUEST":            { status: 400, code: "BAD_REQUEST" },
  "APIKIT:NOT_FOUND":              { status: 404, code: "RESOURCE_NOT_FOUND" },
  "APIKIT:METHOD_NOT_ALLOWED":     { status: 405, code: "METHOD_NOT_ALLOWED" },
  "APIKIT:NOT_ACCEPTABLE":         { status: 406, code: "NOT_ACCEPTABLE" },
  "APIKIT:UNSUPPORTED_MEDIA_TYPE": { status: 415, code: "UNSUPPORTED_MEDIA_TYPE" },
  "APP:NOT_FOUND":                 { status: 404, code: "NOT_FOUND" },
  "APP:CONFLICT":                  { status: 409, code: "CONFLICT" },
  "DB:CONNECTIVITY":               { status: 503, code: "FINANCE_DB_UNAVAILABLE", message: "The finance database is unavailable. Retry later." },
  "DB:RETRY_EXHAUSTED":            { status: 503, code: "FINANCE_DB_UNAVAILABLE", message: "The finance database is unavailable. Retry later." }
}

// Oracle errors raised by the stored procedures and constraints.
// -20xxx are application errors: their text is written for callers.
var byOracleCode = {
  "ORA-20001": { status: 400, code: "VALIDATION_FAILED" },
  "ORA-20002": { status: 404, code: "INVOICE_NOT_FOUND" },
  "ORA-20003": { status: 409, code: "INVOICE_VOID" },
  "ORA-00001": { status: 409, code: "DUPLICATE_KEY", message: "A record with the same key already exists." },
  "ORA-02290": { status: 400, code: "VALIDATION_FAILED", message: "A value is outside the allowed range." },
  "ORA-01400": { status: 400, code: "VALIDATION_FAILED", message: "A required value is missing." }
}

var fallback = {
  status: 500,
  code: "INTERNAL_ERROR",
  message: "Unexpected error. Quote the correlation ID when you contact support."
}

fun oracleCode(text: String) = (text scan /ORA-\d{5}/)[0][0]

// "ORA-20002: Unknown invoice INV-1\nORA-06512: at ..." -> "Unknown invoice INV-1"
fun oracleMessage(text: String) =
  trim(((text scan /ORA-\d{5}: ([^\r\n]*)/)[0][1]) default "")

fun classify(err) = do {
  var errorType = "$(err.errorType.namespace default 'MULE'):$(err.errorType.identifier default 'UNKNOWN')"
  var text = "$(err.description default '') $(err.detailedDescription default '')"
  var ora = oracleCode(text)
  var oracleMatch = if (ora != null) byOracleCode[ora] else null
  var typeMatch = byType[errorType]
  ---
  if (oracleMatch != null)
    (oracleMatch - "message") ++ { message: oracleMatch.message default oracleMessage(text) }
  else if (typeMatch != null)
    (typeMatch - "message") ++ { message: typeMatch.message default (err.description default typeMatch.code) }
  else
    fallback
}
