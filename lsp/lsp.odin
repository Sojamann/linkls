package lsp

import "core:os"
import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:mem"

import "../rpc"

MAX_REQUEST_SIZE :: 1 * 1024 * 1024 // 1MiB
MAX_RESPONSE_SIZE :: 1 * 1024       // 1KiB

serve :: proc(lsp_handler: LspHandler) {
  // rpc uses the heap for allocating the buffer which
  // will be managed by the scanner and internally
  // reused
  rpc_handler := rpc.init(
    os.stream_from_handle(os.stdin),
    os.stream_from_handle(os.stdout),
  )
  defer rpc.destroy(&rpc_handler)

  // all allocations that are used for (un)marshalling the data
  // should use this arena allocator which will be reset after
  // each message
  buff, err := mem.alloc_bytes(MAX_REQUEST_SIZE + MAX_RESPONSE_SIZE)
  assert(err == .None, "OOM")
  defer delete(buff)

  arena: mem.Arena 
  mem.arena_init(&arena, buff)
  ally := mem.arena_allocator(&arena)

  for {
    defer mem.arena_free_all(&arena)

    msg := rpc.read(&rpc_handler)
    log.debug("received", string(msg))

    resp, shutdown := handle(lsp_handler, msg, ally)
    if shutdown {
      return
    }
    if response_text, ok := resp.?; ok {
      log.debug("responding with", response_text)
      rpc.write(&rpc_handler, transmute([]u8)response_text)
    }
  }
}

@(private)
handle :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) -> (Maybe(string), bool) {
  req: struct {
    method: string,
  }

  if json.unmarshal(msg, &req, allocator=ally) != nil {
    log.error("lsp: could not unmarshal message:", string(msg))
    return respond_fail(-1, {.InvalidRequest, "request without method"}, ally), false
  }

  log.info("received", req.method, "request/notification")

  switch req.method {
    case "initialize":
      return handleInitialize(handler, msg, ally), false
    case "textDocument/didOpen":
      handle_did_open(handler, msg, ally)
    case "textDocument/didSave":
      handle_did_save(handler, msg, ally)
    case "textDocument/didChange":
      handle_did_change(handler, msg, ally)
    case "textDocument/didClose":
      handle_did_close(handler, msg, ally)
    case "textDocument/definition":
      return handle_definition(handler, msg, ally), false
    case "initialized": // notification
    case "shutdown":
      return handle_shutdown(msg, ally), false
    case "exit": // notification
      return nil, true
    case:
      log.warn("lsp: no handler for method", req.method)
  }
  return nil, false
}
