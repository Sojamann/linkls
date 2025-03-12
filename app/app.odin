package app

import "core:mem"

Linkls :: struct {
  roots: []string,
  ignore_files: []string,
  buffers: map[string]string,
}

init :: proc() -> Linkls {
  return Linkls{
    roots=nil,
    buffers=make(map[string]string),
  }
}

destroy :: proc(app: ^Linkls) {
  for key in app.roots {
    delete(key)
  }
  delete(app.roots)

  for key in app.ignore_files {
    delete(key)
  }
  delete(app.ignore_files)

  for key, &value in app.buffers {
    delete(key)
    delete(value)
  }
  delete_map(app.buffers)
}
