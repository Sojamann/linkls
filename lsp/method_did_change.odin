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
      version: int,
    },
    // we don't receive partial updates since we use full
    // sync for documents
    contentChanges: []struct{
      text: string,
    },
  },
}

handle_did_change :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) {
  notification: Notification
  if json.unmarshal(msg, &notification, allocator=ally) != nil {
    log.fatal("could not unmarshal textDocument/didChange request", msg)
    return
  }

  fn, ok := handler.change.?
  if !ok {
    return
  }

  log.debug("<-  textDocument/didChange handler")
  fn(
    handler.userdata,
    notification.params.textDocument.uri,
    // since we do not receive partial updates here but only full ones
    // the last "change" will be most recent state/text of the document
    notification.params.contentChanges[len(notification.params.contentChanges)-1].text,
  )
  log.debug("->  textDocument/didChange handler")
}
