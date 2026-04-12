local utils = require('lsp._utils')

---@type vim.lsp.Config
local config = {
  cmd = function(dispatchers, cfg)
    local cmd = { 'ty', 'server' }
    if utils.has_uv_project(cfg.root_dir) then
      cmd = { 'uv', 'run', '--directory', cfg.root_dir, 'ty', 'server' }
    end

    return require('vim.lsp.rpc').start(cmd, dispatchers, {
      cwd = cfg.root_dir,
    })
  end,
  filetypes = { 'python' },
  root_markers = { 'ty.toml', 'uv.lock', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
}

return config
