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
    local cmd = { 'pyright-langserver', '--stdio' }
    if has_uv_project(cfg.root_dir) then
      cmd = { 'uv', 'run', '--directory', cfg.root_dir, 'pyright-langserver', '--stdio' }
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
  settings = {
    python = {
      pythonPath = '.venv/bin/python',
      venvPath = '.',
      analysis = {
        -- Unlike the other keys, this one turns false when absent from an analysis table.
        autoSearchPaths = true,
        diagnosticMode = 'workspace',
      },
    },
  },
}

return config
