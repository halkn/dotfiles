---@type vim.lsp.Config
local config = {
  cmd = { 'ryl', 'server' },
  filetypes = { 'yaml' },
  root_markers = {
    '.ryl.toml',
    'ryl.toml',
    '.git',
  },
  single_file_support = true,
}

return config
