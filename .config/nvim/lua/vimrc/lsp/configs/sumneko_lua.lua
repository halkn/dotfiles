local util = require('vimrc/lsp/util')
local base_path = util.get_lspinstall_path() .. '/lua'
local Config = util.get_config()

Config.cmd = {
  base_path .. '/sumneko-lua-language-server',
  "-E",
  base_path .. 'sumneko-lua/extension/server/main.lua'
}

Config.settings = {
  Lua = {
    runtime = {
      version = 'LuaJIT',
      path = vim.split(package.path, ';'),
    },
    diagnostics = {
      globals = {'vim'},
    },
    workspace = {
      library = {
        [vim.fn.expand('$VIMRUNTIME/lua')] = true,
        [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
      },
    },
    telemetry = {
      enable = false,
    },
  },
}

return Config
