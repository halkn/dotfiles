---@type vim.lsp.Config
return {
  cmd = { 'mise', 'lsp' },
  -- mise lsp answers only for the files mise loads as config and ignores other TOML, so it
  -- attaches to every toml buffer.
  filetypes = { 'toml' },
  root_markers = { 'mise.toml', '.git' },
}
