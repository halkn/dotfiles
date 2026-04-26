--- @type vim.lsp.Config
local config = {
  cmd = { require('tools').resolve('lua-language-server') },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    '.git',
  },
  single_file_support = true,
}

return config
