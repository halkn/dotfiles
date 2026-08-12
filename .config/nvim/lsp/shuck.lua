---@type vim.lsp.Config
return {
  cmd = { 'shuck', 'server' },
  filetypes = { 'zsh', 'bash', 'sh' },
  root_markers = {
    '.shuck.toml',
    'shuck.toml',
    '.git/',
  },
}
