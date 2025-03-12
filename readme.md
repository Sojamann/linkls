# LINKLS
A toy language server implementing *goto definition* for `#tag`
bringing you to the first occurrence of `[tag]`.

## Configuration
### Neovim
```lua
local lspconfig = require 'lspconfig'
local configs = require 'lspconfig.configs'

configs.linkls = {
    default_config = {
        cmd = { 
            -- in PATH
            "linkls",
            -- local path
            -- vim.fn.expand("~/path/to/binary")
        },
        
        init_options = {
            -- which paths to ignore when searching
            ignore_files = {".git", "node_modules" }
        }
    },
}
lspconfig.linkls.setup {}

```

## Building
```bash
odin build .
# with leak checking and logging to /tmp/linkls.log
odin build . -debug
```

# TODO
- [ ] improve handover of init options from lsp package to app package
- [ ] searching on demand is kinda slow ... one could
    search every file in the background and monitor for file
    changes refreshing the index when needed.
