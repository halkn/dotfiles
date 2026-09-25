local lockfiles = { 'bun.lock', 'bun.lockb', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock' }

---@type vimrc.lsp.Config
local config = {
  -- node_modules/.bin/oxfmt has a node shebang; --bun runs it on bun, and --no-install keeps
  -- bunx from fetching a formatter the project does not declare.
  cmd = function(dispatchers, cfg)
    return require('vim.lsp.rpc').start(
      { 'bun', 'x', '--bun', '--no-install', 'oxfmt', '--lsp' },
      dispatchers,
      { cwd = cfg.root_dir }
    )
  end,
  -- oxfmt also formats markdown and yaml; those stay with rumdl and ryl so a file formats the
  -- same inside and outside a JS project.
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { lockfiles })
    if root and vim.uv.fs_stat(vim.fs.joinpath(root, 'node_modules', '.bin', 'oxfmt')) then
      on_dir(root)
    end
  end,
}

return config
