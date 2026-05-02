---@type vim.lsp.Config
local config = {
  cmd = function(dispatchers, cfg)
    return require('vim.lsp.rpc').start({ 'rumdl', 'server' }, dispatchers, {
      cwd = cfg.root_dir,
    })
  end,
  filetypes = { 'markdown' },
  root_markers = {
    '.rumdl.toml',
    'rumdl.toml',
    'pyproject.toml',
    '.git',
  },
  single_file_support = true,
}

return config
