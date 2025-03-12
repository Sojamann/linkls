package lsp

import "core:log"
import "core:mem"
import "core:encoding/json"

@(private="file")
Notification :: struct {
  id: int,
  params: struct {
    textDocument: struct{
      uri: string,
    },

    text: string,
  },
}

handle_did_save :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) {
  notification: Notification
  if json.unmarshal(msg, &notification, allocator=ally) != nil {
    log.fatal("could not unmarshal textDocument/didSave request", msg)
    return
  }

  fn, ok := handler.save.?
  if !ok {
    return
  }

  log.debug("-> textDocument/didSave")
  fn(
    handler.userdata,
    notification.params.textDocument.uri,
    notification.params.text,
  )
  log.debug("<- textDocument/didSave")
}
