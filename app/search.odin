package app

import "core:fmt"
import "core:slice"
import "core:bytes"
import "core:log"
import "core:strings"
import "core:os"
import "core:path/filepath"

import "../lsp"

search :: proc(
  root: string,
  tag_name: string,
  ignore_files: []string,
) -> Maybe(lsp.Location) {
  log.info("searching", root, "for", tag_name)

  State :: struct {
    tag_name: string,
    ignore_files: []string,
    finding: Maybe(lsp.Location),
  }

  walker :: proc(info: os.File_Info, in_err: os.Error, user_data: rawptr) -> (err: os.Error, skip_dir: bool) {
    if info.is_dir || info.fullpath == "" {
      return
    }

    state := transmute(^State)user_data
    log.debug("searching", info.fullpath)

    if slice.contains(state.ignore_files, info.name) {
      log.debug("ignoring", info.name)
      return nil, true
    }

    content, ok := os.read_entire_file(info.fullpath)
    if !ok {
      log.fatal("could not read file", info.fullpath)
      return
    }
    defer delete(content)

    builder := strings.builder_make_none()
    defer strings.builder_destroy(&builder)

    strings.write_rune(&builder, '[')
    strings.write_string(&builder, state.tag_name)
    strings.write_rune(&builder, ']')

    lines := strings.split_lines(string(content))
    defer delete(lines)

    // we only search for the first occurrence
    for line, i in lines {
      start := strings.index(line, strings.to_string(builder))
      if start < 0 {
        break
      }

      end := bytes.index_rune(content[start:], ']')

      log.debug("found something at line", line, "offset", start)

      uri_builder := strings.builder_make_none() // free'd by caller
      strings.write_string(&uri_builder, "file://")
      strings.write_string(&uri_builder, info.fullpath)

      state.finding = lsp.Location{
        uri=strings.to_string(uri_builder),
        range={
          start={line=transmute(uint)i, character=transmute(uint)start},
          end={line=transmute(uint)i, character=transmute(uint)end},
        },
      }
      return
    }

    return // the default return values are ok
  }

  state := State {
    tag_name=tag_name,
    ignore_files=ignore_files,
    finding=nil,
  }

  filepath.walk(root, walker, &state)
  return state.finding
}
