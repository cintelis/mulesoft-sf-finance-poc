%dw 2.0
import classify from modules::Errors
output application/json
var c = classify(error)
---
{
  error: {
    code: c.code,
    message: c.message,
    correlationId: correlationId,
    timestamp: now() as String { format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX" }
  }
}
