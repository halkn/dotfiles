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
    local cmd = { 'ruff', 'server' }
    if has_uv_project(cfg.root_dir) then
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
  -- The Python type checker owns hover. Deciding this on LspAttach would depend
  -- on which client attaches first, so it is settled before any request is sent.
  on_init = function(client)
    client.server_capabilities.hoverProvider = false
  end,
  settings = {
    organizeImports = true,
    fixAll = true,
  },
}

return config
