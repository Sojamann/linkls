package lsp

LspHandler :: struct {
  userdata: rawptr,

  init: proc(userdata: rawptr, roots: []string, ignore_files: []string) -> (error: Maybe(string)),

  open: Maybe(proc(userdata: rawptr, uri: string, text: string)),
  close: Maybe(proc(userdata: rawptr, uri: string)),
  change: Maybe(proc(userdata: rawptr, uri: string, text: string)),
  save: Maybe(proc(userdata: rawptr, uri: string, text: string)),

  definition: Maybe(proc(userdata: rawptr, uri: string, position: Position) -> Maybe(Location)),
}

