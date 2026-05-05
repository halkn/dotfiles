local M = {}

local function join(...)
  return vim.fs.joinpath(...)
end

local function executable_name(tool)
  return tool.executable or tool.name
end

M.root = vim.g.nvim_tools_root or join(vim.fn.stdpath('data'), 'managed-tools')

M.registry = {
  ['lua-language-server'] = {
    name = 'lua-language-server',
    repo = 'LuaLS/lua-language-server',
    asset_pattern = 'lua%-language%-server%-.*linux%-x64%.tar%.gz$',
    executable = 'lua-language-server',
    executable_path = join('bin', 'lua-language-server'),
  },
  stylua = {
    name = 'stylua',
    repo = 'JohnnyMorganz/StyLua',
    asset_pattern = 'stylua%-linux%-x86_64%.zip$',
    executable = 'stylua',
    executable_path = 'stylua',
  },
  shfmt = {
    name = 'shfmt',
    repo = 'mvdan/sh',
    asset_pattern = 'shfmt_v[%d%.]+_linux_amd64$',
    asset_type = 'binary',
    executable = 'shfmt',
    executable_path = 'shfmt',
  },
  shellcheck = {
    name = 'shellcheck',
    repo = 'koalaman/shellcheck',
    asset_pattern = 'shellcheck%-v[%d%.]+%.linux%.x86_64%.tar%.xz$',
    executable = 'shellcheck',
    executable_glob = 'shellcheck-*/shellcheck',
  },
  ['yaml-language-server'] = {
    name = 'yaml-language-server',
    package = 'yaml-language-server',
    package_manager = 'bun',
    executable = 'yaml-language-server',
    executable_path = join('node_modules', '.bin', 'yaml-language-server'),
  },
  ['tree-sitter'] = {
    name = 'tree-sitter',
    common = true,
    repo = 'tree-sitter/tree-sitter',
    asset_pattern = 'tree%-sitter%-cli%-linux%-x64%.zip$',
    executable = 'tree-sitter',
    executable_path = 'tree-sitter',
  },
}

function M.path(...)
  return join(M.root, ...)
end

function M.bin_dir()
  return M.path('bin')
end

function M.opt_dir(name)
  return M.path('opt', name)
end

function M.package_dir(name)
  return M.path('packages', name)
end

function M.resolve(name)
  local tool = M.registry[name]
  if tool == nil then
    error(('unknown managed tool: %s'):format(name))
  end

  return join(M.bin_dir(), executable_name(tool))
end

function M.executable(name)
  local path = M.resolve(name)
  if vim.fn.executable(path) == 1 then
    return path
  end

  vim.notify(
    ('Neovim managed tool is missing: %s (run :NvimToolsInstall %s)'):format(name, name),
    vim.log.levels.WARN
  )
  return path
end

function M.is_installed(name)
  local path = M.resolve(name)
  return vim.fn.executable(path) == 1
end

function M.list()
  local names = vim.tbl_keys(M.registry)
  table.sort(names)
  return vim.tbl_map(function(name)
    return {
      name = name,
      path = M.resolve(name),
      installed = M.is_installed(name),
    }
  end, names)
end

function M.required_by_languages()
  local by_tool = {}
  local ok, lang = pcall(require, 'lang')
  if not ok then
    return by_tool
  end

  for language_name, language in pairs(lang.languages) do
    if language.enabled and language.tools then
      for _, tool_name in ipairs(language.tools) do
        by_tool[tool_name] = by_tool[tool_name] or {}
        table.insert(by_tool[tool_name], language_name)
      end
    end
  end

  return by_tool
end

function M.default_tools()
  local selected = {}
  local required = M.required_by_languages()

  for name in pairs(required) do
    selected[name] = true
  end

  for name, tool in pairs(M.registry) do
    if tool.common then
      selected[name] = true
    end
  end

  return selected
end

return M
