package lsp

import "core:encoding/json"
import "core:mem"
import "core:log"

@(private="file")
Request :: struct {
  id: int,
  params: struct {
    textDocument: struct {
      uri: string,
    },
    position: Position,
    //workDoneToken: Maybe(string), // interface WorkDoneProgressParams
    //partialResultToken: Maybe(string), // interface PartialResultParams
  },
}

handle_definition :: proc(
  handler: LspHandler,
  msg: []u8,
  ally: mem.Allocator,
) -> string {
  req: Request
  if err := json.unmarshal(msg, &req, allocator=ally); err != nil {
    log.error("could not unmarshal textDocument/definition request", string(msg), "due to", err)
    return respond_fail(
      -1,
      {.InvalidRequest, "invalid textDocument/definition request"},
      ally,
    )
  }

  fn, ok := handler.definition.?
  if !ok {
    return respond_ok(req.id, cast([]Location)nil, ally)
  }

  log.debug("-> textDocument/definition")
  location := fn(
    handler.userdata,
    req.params.textDocument.uri,
    req.params.position,
  )
  log.debug("<- textDocument/definition")

  if loc, ok := location.?; ok {
    defer delete(loc.uri)
  }
  return respond_ok(req.id, location, ally)
}

