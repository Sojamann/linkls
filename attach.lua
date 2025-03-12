local lspconfig = require 'lspconfig'
local configs = require 'lspconfig.configs'

if not configs.linkls then
  configs.linkls = {
    default_config = {
      cmd = { vim.fn.expand("~/Repos/linkls/linkls") },
      root_dir = lspconfig.util.root_pattern('.git'),
      init_options = {
        ignore_files = {".git", "node_modules" }
      }
    },
  }
end
lspconfig.linkls.setup {}

-- local client = vim.lsp.start_client {
--   name = "linkr",
--   cmd = { "/home/robin/Repos/linkls/linkls" },
-- }
-- if not client then
--   vim.notify "lsp attach did not work"
--   return
-- end
--
-- vim.lsp.buf_attach_client(0, client)
--
-- vim.api.nvim_create_autocmd("FileType", {
--   callback = function()
--     vim.lsp.buf_attach_client(0, client)
--   end
-- })
