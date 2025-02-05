local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

--- @type vim.lsp.Config
local config = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
    'selene.yml',
    '.git',
  },
  single_file_support = true,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      diagnostics = {
        globals = { 'vim' },
      },
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
        }
      },
      completion = {
        callSnippet = 'Disable',
        keywordSnippet = 'Disable',
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "/lazy/lazy.nvim/lua"),
          vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "/lazy/blink.cmp/lua"),
          vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "/lazy/snacks.nvim/lua"),
          vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "lua"),
          vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
          "${3rd}/luv/library",
        },
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

return config
