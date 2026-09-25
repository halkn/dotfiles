local lockfiles = { 'bun.lock', 'bun.lockb', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock' }

-- `--lsp` exists only in the native compiler (TypeScript 7+); older versions exit on the flag.
local function has_native_typescript(root_dir)
  local path = vim.fs.joinpath(root_dir, 'node_modules', 'typescript', 'package.json')
  local ok, pkg = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  local version = ok and type(pkg) == 'table' and vim.version.parse(pkg.version or '') or nil
  return version ~= nil and version.major >= 7
end

---@type vimrc.lsp.Config
local config = {
  -- node_modules/.bin/tsc has a node shebang; --bun runs it on bun, and --no-install keeps
  -- bunx from fetching a TypeScript the project does not declare.
  cmd = function(dispatchers, cfg)
    return require('vim.lsp.rpc').start(
      { 'bun', 'x', '--bun', '--no-install', 'tsc', '--lsp', '--stdio' },
      dispatchers,
      { cwd = cfg.root_dir }
    )
  end,
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { lockfiles })
    if root and has_native_typescript(root) then
      on_dir(root)
    end
  end,
  -- oxfmt owns formatting, so saving never runs two formatters with different styles.
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  format_code_actions = { 'source.organizeImports' },
  settings = {
    ['js/ts'] = {
      inlayHints = {
        parameterNames = { enabled = 'literals', suppressWhenArgumentMatchesName = true },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}

return config
