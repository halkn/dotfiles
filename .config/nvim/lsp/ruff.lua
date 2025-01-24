---@type vim.lsp.Config
local config = {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'requirements.txt',
    'uv.lock',
    '.git',
  },
  single_file_support = true,
  settings = {
    organizeImports = true,
    fixAll = true,
  },
}

return config
