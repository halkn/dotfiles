local utils = require('lsp._utils')

---@type vim.lsp.Config
local config = {
  cmd = function(dispatchers, cfg)
    local cmd = { 'ruff', 'server' }
    if utils.has_uv_project(cfg.root_dir) then
      cmd = { 'uv', 'run', '--directory', cfg.root_dir, 'ruff', 'server' }
    end

    return require('vim.lsp.rpc').start(cmd, dispatchers, {
      cwd = cfg.root_dir,
    })
  end,
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
