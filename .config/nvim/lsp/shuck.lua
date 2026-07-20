---@type vim.lsp.Config
return {
  cmd = { 'shuck', 'server' },
  filetypes = { 'zsh', 'bash', 'sh' },
  root_markers = {
    '.shuck.toml',
    'shuck.toml',
    '.git/',
  },
  single_file_support = true,
}
