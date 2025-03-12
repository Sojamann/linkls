package rpc

import "core:log"
import "core:bytes"
import "core:mem"
import "core:strings"
import "core:os"
import "core:io"
import "core:bufio"
import "core:strconv"
import "core:fmt"

@(private)
rpc_splitter :: proc(data: []u8, at_eof: bool) -> (advance: int, token: []byte, err: bufio.Scanner_Error, final_token: bool) {
  index := bytes.index(data, []u8{'\r', '\n', '\r', '\n'})
  if index < 0 {
    return
  }

  header := data[:index]
  content := data[index + 4:]

  // NOTE: the header could contain multiple key-value pairs
  content_len_bytes := header[len("Content-Length: "):]
	content_len := strconv.atoi(string(content_len_bytes))

  if len(content) < content_len {
    return
  }
  advance = len(header) + 4 + content_len
  //token = data[:advance]
  token = data[len(header)+4:advance]
  return
}

Handler :: struct {
  scanner: bufio.Scanner,
  output: io.Stream,
}

init :: proc(
  input_stream: io.Stream,
  output_stream: io.Stream,
  ally: mem.Allocator = context.allocator,
) -> Handler {
	scanner: bufio.Scanner
	bufio.scanner_init(&scanner, input_stream, ally)
  scanner.split = rpc_splitter

  return {
    scanner=scanner,
    output=output_stream,
  }
}

destroy :: proc(handler: ^Handler) {
  bufio.scanner_destroy(&handler.scanner)
}

read :: proc(handler: ^Handler) -> []u8 {
  if ! bufio.scanner_scan(&handler.scanner) {
    fmt.panicf("rpc error: {}", bufio.scanner_error(&handler.scanner))
  }
  return bufio.scanner_bytes(&handler.scanner)
}

write :: proc(handler: ^Handler, msg: []u8) {
  io.write_string(handler.output, "Content-Length: ")
  io.write_int(handler.output, len(msg))
  io.write_string(handler.output, "\r\n\r\n")
  io.write(handler.output, msg)
}
