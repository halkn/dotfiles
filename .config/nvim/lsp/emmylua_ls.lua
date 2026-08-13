---@type vim.lsp.Config
return {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = {
    '.emmyrc.json',
    '.emmyrc.lua',
    '.luarc.json',
    '.git',
  },
}
