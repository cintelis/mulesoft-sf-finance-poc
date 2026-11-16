%dw 2.0

// Maps a Mule error to an HTTP status, a stable error code and a message that
// is safe to show a caller. Used by the global error handler.

var unavailable = { status: 503, code: "SALESFORCE_UNAVAILABLE", message: "Salesforce is unavailable. Retry later." }

var byType = {
  "APIKIT:BAD_REQUEST":            { status: 400, code: "BAD_REQUEST" },
  "APIKIT:NOT_FOUND":              { status: 404, code: "RESOURCE_NOT_FOUND" },
  "APIKIT:METHOD_NOT_ALLOWED":     { status: 405, code: "METHOD_NOT_ALLOWED" },
  "APIKIT:NOT_ACCEPTABLE":         { status: 406, code: "NOT_ACCEPTABLE" },
  "APIKIT:UNSUPPORTED_MEDIA_TYPE": { status: 415, code: "UNSUPPORTED_MEDIA_TYPE" },
  "APP:NOT_FOUND":                 { status: 404, code: "NOT_FOUND" },
  "SALESFORCE:INVALID_INPUT":      { status: 400, code: "SALESFORCE_REJECTED" },
  "SALESFORCE:NOT_FOUND":          { status: 404, code: "NOT_FOUND" },
  "SALESFORCE:LIMIT_EXCEEDED":     { status: 503, code: "SALESFORCE_LIMIT_EXCEEDED", message: "A Salesforce API limit was reached. Retry later." },
  "SALESFORCE:CONNECTIVITY":       unavailable,
  "SALESFORCE:TIMEOUT":            unavailable,
  "SALESFORCE:RETRY_EXHAUSTED":    unavailable
}

var fallback = {
  status: 500,
  code: "INTERNAL_ERROR",
  message: "Unexpected error. Quote the correlation ID when you contact support."
}

fun classify(err) = do {
  var errorType = "$(err.errorType.namespace default 'MULE'):$(err.errorType.identifier default 'UNKNOWN')"
  var typeMatch = byType[errorType]
  ---
  if (typeMatch != null)
    { message: err.description default typeMatch.code } ++ typeMatch
  else
    fallback
}
