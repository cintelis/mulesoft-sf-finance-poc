%dw 2.0
output application/json
// Change Data Capture event -> a small, stable event for the process API.
// The event carries only the fields that changed, so the process API reads the
// full Account by ID before it syncs.
var body = payload.data.payload default (payload.payload default payload)
var header = body.ChangeEventHeader default {}
---
{
  eventId: header.transactionKey default correlationId,
  replayId: payload.data.event.replayId default payload.event.replayId,
  changeType: header.changeType,
  accountIds: header.recordIds default [],
  changedFields: header.changedFields default [],
  committedAt: header.commitTimestamp,
  changeOrigin: header.changeOrigin
}
