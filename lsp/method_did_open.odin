package lsp

import "core:os"
import "core:log"
import "core:mem"
import "core:encoding/json"

@(private="file")
Notification :: struct {
  params: struct {
    textDocument: struct {
      uri: string,
      languageId: string,
      text: Maybe(string),
    },
  },
}

handle_did_open :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) {
  notification: Notification
  os.write_entire_file("/tmp/test.log", msg)
  if err := json.unmarshal(msg, &notification, allocator=ally); err != nil {
    log.fatal("could not unmarshal textDocument/didOpen request due to", err)
    return
  }

  fn, ok := handler.open.?
  if !ok {
    return
  }

  log.debug("-> textDocument/didOpen")
  fn(
    handler.userdata,
    notification.params.textDocument.uri,
    notification.params.textDocument.text.? or_else "",
  )
  log.debug("<- textDocument/didOpen")
}
