package lsp

Position :: struct {
  line: uint,
  character: uint,
}

Location :: struct {
  uri: string,
  range: struct {
    start: Position,
    end: Position,
  }
}

ResponseError :: struct {
  code: ErrorCode,
  message: string,
}

ErrorCode :: enum int {
  // Defined by JSON-RPC
	ParseError = -32700,
	InvalidRequest = -32600,
	MethodNotFound = -32601,
	InvalidParams = -32602,
	InternalError = -32603,

	/**
	 * Error code indicating that a server received a notification or
	 * request before the server has received the `initialize` request.
	 */
	ServerNotInitialized = -32002,

	/**
	 * A request failed but it was syntactically correct, e.g the
	 * method name was known and the parameters were valid. The error
	 * message should contain human readable information about why
	 * the request failed.
	 *
	 * @since 3.17.0
	 */
	RequestFailed = -32803,
}
