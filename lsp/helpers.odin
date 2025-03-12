package lsp

import "core:mem"
import "core:encoding/json"

@(private)
respond_ok :: proc(
  request_id: int,
  result: $ResultType,
  ally: mem.Allocator,
) -> string {
  Response :: struct {
    jsonrpc: string,
    id: int,
    result: ResultType,
  }

  response := Response{
    jsonrpc="2.0",
    id=request_id,
    result=result,
  }

  data, err := json.marshal(response, allocator=ally)
  if err != nil {
    panic("failed marshalling response")
  }
  return string(data)
}

@(private)
respond_fail :: proc (
  request_id: int,
  error: ResponseError,
  ally: mem.Allocator,
) -> string {
  Response :: struct {
    jsonrpc: string,
    id: int,
    error: ResponseError,
  }

  response := Response{
    jsonrpc="2.0",
    id=request_id,
    error=error,
  }

  data, err := json.marshal(response, allocator=ally)
  if err != nil {
    panic("failed marshalling response")
  }
  return string(data)
}
