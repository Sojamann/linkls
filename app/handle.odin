package app

import "core:slice"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:os"
import "../lsp"

to_handler :: proc(app: ^Linkls) -> lsp.LspHandler {
  return {
    userdata=app,
    init=handle_initialize,
    open=handle_text_update,
    change=handle_text_update,
    close=handle_close,
    save=handle_text_update,
    definition=handle_definition,
  }
}

@(private="file")
handle_initialize :: proc(
  userdata: rawptr,
  roots: []string,
  ignore_files: []string,
) -> (error: Maybe(string)) {
  if len(roots) <= 0 {
    return "linkls requires a workspace directory to be set"
  }

  app := transmute(^Linkls)userdata
  app.roots = slice.clone(roots)
  for root, i in app.roots {
    app.roots[i] = strings.clone(root)
  }
  app.ignore_files = slice.clone(ignore_files)
  for file, i in app.ignore_files {
    app.ignore_files[i] = strings.clone(file)
  }
  return nil
}

@(private="file")
handle_text_update :: proc(
  userdata: rawptr,
  uri: string,
  text: string,
) {
  app := transmute(^Linkls)userdata
  app.buffers[strings.clone(uri)] = strings.clone(text)
}

@(private="file")
handle_close :: proc(
  userdata: rawptr,
  uri: string,
) {
  app := transmute(^Linkls)userdata
  delete_key(&app.buffers, uri)
}


@(private="file")
handle_definition :: proc(
  userdata: rawptr,
  uri: string,
  position: lsp.Position,
) -> Maybe(lsp.Location) {
  // are we on #SomeLabel
  //
  // find [some label]
  app := transmute(^Linkls)userdata

  content, exists := app.buffers[uri]
  if !exists {
    fmt.panicf("there should be a known buffer for uri {}", uri)
  }

  lines := strings.split_lines(content)
  defer delete(lines)
  line := lines[position.line]

  right_bound := strings.index_any(line[position.character:], " \t\n")
  if right_bound < 0 {
    right_bound = len(line)
  }

  left_bound := strings.last_index_any(line[:position.character+1], " \t\n")
  if left_bound < 0 {
    left_bound = 0 
  }

  tag_name := line[left_bound+1:right_bound]
  if ! strings.starts_with(tag_name, "#") {
    return nil
  }
  tag_name = tag_name[1:]

  for root in app.roots {
    loc, found := search(strings.trim_prefix(root, "file://"), tag_name, app.ignore_files).?
    if found { return loc }
  }
  return nil
}

