package lsp

import "core:log"
import "core:mem"
import "core:encoding/json"

@(private="file")
Notification :: struct {
  id: int,
  params: struct {
    /**
      * The document that was closed.
      */
    textDocument: struct {
      uri: string,
    },
  },
}

handle_did_close :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) {
  notification: Notification
  if json.unmarshal(msg, &notification, allocator=ally) != nil {
    log.fatal("could not unmarshal textDocument/didClose request", msg)
    return
  }

  fn, ok := handler.close.?
  if !ok {
    return
  }

  log.debug("started  textDocument/didClose handler")
  fn(handler.userdata, notification.params.textDocument.uri)
  log.debug("finished textDocument/didClose handler")
}
