%dw 2.0

// Maps a Mule error to an HTTP status, a stable error code and a message that
// is safe to show a caller. Used by the global error handler.

var unavailable = { status: 503, code: "UPSTREAM_UNAVAILABLE", message: "A system API is unavailable. Retry later." }

var byType = {
  "APIKIT:BAD_REQUEST":            { status: 400, code: "BAD_REQUEST" },
  "APIKIT:NOT_FOUND":              { status: 404, code: "RESOURCE_NOT_FOUND" },
  "APIKIT:METHOD_NOT_ALLOWED":     { status: 405, code: "METHOD_NOT_ALLOWED" },
  "APIKIT:NOT_ACCEPTABLE":         { status: 406, code: "NOT_ACCEPTABLE" },
  "APIKIT:UNSUPPORTED_MEDIA_TYPE": { status: 415, code: "UNSUPPORTED_MEDIA_TYPE" },
  "APP:BAD_FILE":                  { status: 400, code: "BAD_FILE" },
  "APP:UPSTREAM_REJECTED":         { status: 502, code: "UPSTREAM_REJECTED" },
  "MULE:RETRY_EXHAUSTED":          unavailable,
  "HTTP:CONNECTIVITY":             unavailable,
  "HTTP:TIMEOUT":                  unavailable
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
    (typeMatch - "message") ++ { message: typeMatch.message default (err.description default typeMatch.code) }
  else
    fallback
}
