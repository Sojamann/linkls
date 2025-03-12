package main

import "core:encoding/json"
import "core:log"
import "core:bytes"
import "core:mem"
import "core:strings"
import "core:os"
import "core:io"
import "core:bufio"
import "core:strconv"
import "core:fmt"

import "lsp"
import "app"

// #FOO
main :: proc() {
  when ODIN_DEBUG {
    file, err := os.open("/tmp/linkls.log", flags=os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode=0o0600)
    if err != nil {
      fmt.panicf("cannot open log file {}", err)
    }
    defer os.close(file)

    logger := log.create_file_logger(file)
    defer log.destroy_file_logger(logger)
    context.logger = logger

    // ----

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
      if len(track.allocation_map) > 0 {
        log.errorf("=== %v allocations not freed: ===\n", len(track.allocation_map))
        for _, entry in track.allocation_map {
          log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
        }
      }
      mem.tracking_allocator_destroy(&track)
    }
  }

  //--------
  linkls := app.init()
  defer app.destroy(&linkls)
  lsp.serve(app.to_handler(&linkls))
}
