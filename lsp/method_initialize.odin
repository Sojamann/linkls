package lsp

import "core:slice"
import "core:mem"
import "core:encoding/json"
import "core:strings"
import "core:log"

@(private="file")
ServerCapabilities :: struct {
  definitionProvider: bool,
  textDocumentSync: struct {
    openClose: bool,
    change: enum {
      /**
      * Documents should not be synced at all.
      */
      None = 0,

      /*
      * Documents are synced by always sending the full content
      * of the document.
      */
      Full = 1,

      /**
      * Documents are synced by sending the full content on open.
      * After that only incremental updates to the document are
      * send.
      */
      Incremental = 2,
    },
  },
}

@(private="file")
ServerInfo :: struct {
  name: string,
}

@(private="file")
Result :: struct {
  capabilities: ServerCapabilities,
  serverInfo: Maybe(ServerInfo),
}

@(private="file")
Request :: struct {
  id: int,
  params: struct{
    rootPath: Maybe(string),
    rootUri: Maybe(string),
    workspaceFolders: Maybe([]struct{
      uri: string,
    }),
    initializationOptions: Maybe(struct{
      ignore_files: Maybe([]string),
    }),
  },
}

// returns the response for the request which the receiver must free
handleInitialize :: proc(
  handler: LspHandler,
  data: []u8,
  ally: mem.Allocator,
) -> string {
  req: Request
  if json.unmarshal(data, &req, allocator=ally) != nil {
    return respond_fail(
      -1,
      {code=.ParseError, message="invalid initialize request"},
      ally,
    )
  }

  // collect project roots
  roots := make([dynamic]string, ally)
  defer delete(roots)

  if folders, ok := req.params.workspaceFolders.?; ok {
    for x in folders {
      append_elem(&roots, x.uri)
    }
  } else if root, ok := req.params.rootUri.?; ok {
    append_elem(&roots, root)
  }else if root, ok := req.params.rootPath.?; ok {
    append_elem(&roots, root)
  }

  // collect ignore list
  ignore_files: []string = nil
  if opts, ok := req.params.initializationOptions.?; ok {
    ignore_files = opts.ignore_files.? or_else nil
  }

  log.debug("-> initialize")
  lsp_err := handler.init(handler.userdata, roots[:], ignore_files)
  log.debug("<- initialize")

  if lsp_err, has_err := lsp_err.?; has_err {
    return respond_fail(
      req.id,
      {code=.InvalidParams, message=strings.clone(lsp_err, ally)},
      ally,
    )
  }

  return respond_ok(
    req.id,
    Result{
      capabilities=ServerCapabilities{
        definitionProvider=true,
        textDocumentSync={
          openClose=true,
          change=.Full
        },
      },
      serverInfo=ServerInfo{
        name="linkls",
      },
    },
    ally
  )
}

