local function has_uv_project(root_dir)
  if not root_dir or root_dir == '' then
    return false
  end

  return vim.uv.fs_stat(vim.fs.joinpath(root_dir, 'uv.lock')) ~= nil
    or vim.uv.fs_stat(vim.fs.joinpath(root_dir, '.venv')) ~= nil
end

---@type vim.lsp.Config
local config = {
  cmd = function(dispatchers, cfg)
    local cmd = { 'ty', 'server' }
    if has_uv_project(cfg.root_dir) then
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
