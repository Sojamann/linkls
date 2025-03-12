package lsp

import "core:slice"
import "core:encoding/json"
import "core:log"
import "core:mem"

handle_shutdown :: proc(data: []u8, ally: mem.Allocator) -> string {
  req: struct {
    id: int,
  }

  if err := json.unmarshal(data, &req, allocator=ally); err != nil {
    log.debug("could not unmarshal shutdown request due to", err)
    return respond_fail(-1, {.InvalidRequest, "invalid shutdown request"}, ally)
  }
  return respond_ok(req.id, struct{}{}, ally)
}

