%dw 2.0
import classify from modules::Errors
output application/java
---
classify(error).status
