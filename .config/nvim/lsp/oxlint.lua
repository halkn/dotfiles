local lockfiles = { 'bun.lock', 'bun.lockb', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock' }

---@type vimrc.lsp.Config
local config = {
  -- node_modules/.bin/oxlint has a node shebang; --bun runs it on bun, and --no-install keeps
  -- bunx from fetching a linter the project does not declare.
  cmd = function(dispatchers, cfg)
    return require('vim.lsp.rpc').start(
      { 'bun', 'x', '--bun', '--no-install', 'oxlint', '--lsp' },
      dispatchers,
      { cwd = cfg.root_dir }
    )
  end,
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { lockfiles })
    if root and vim.uv.fs_stat(vim.fs.joinpath(root, 'node_modules', '.bin', 'oxlint')) then
      on_dir(root)
    end
  end,
  format_code_actions = { 'source.fixAll.oxc' },
}

return config
