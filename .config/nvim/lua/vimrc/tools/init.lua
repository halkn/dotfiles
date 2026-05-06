local M = {}

local function join(...)
  return vim.fs.joinpath(...)
end

M.root = vim.g.nvim_tools_root or join(vim.fn.stdpath('data'), 'managed-tools')

M.registry = {
  ['lua-language-server'] = {
    name = 'lua-language-server',
    repo = 'LuaLS/lua-language-server',
    asset_pattern = 'lua%-language%-server%-.*linux%-x64%.tar%.gz$',
    executable_path = join('bin', 'lua-language-server'),
  },
  stylua = {
    name = 'stylua',
    repo = 'JohnnyMorganz/StyLua',
    asset_pattern = 'stylua%-linux%-x86_64%.zip$',
    executable_path = 'stylua',
  },
  shfmt = {
    name = 'shfmt',
    repo = 'mvdan/sh',
    asset_pattern = 'shfmt_v[%d%.]+_linux_amd64$',
    asset_type = 'binary',
    executable_path = 'shfmt',
  },
  ['efm-langserver'] = {
    name = 'efm-langserver',
    repo = 'mattn/efm-langserver',
    asset_pattern = 'efm%-langserver_v[%d%.]+_linux_amd64%.tar%.gz$',
    executable_glob = 'efm-langserver_*/efm-langserver',
  },
  shellcheck = {
    name = 'shellcheck',
    repo = 'koalaman/shellcheck',
    asset_pattern = 'shellcheck%-v[%d%.]+%.linux%.x86_64%.tar%.xz$',
    executable_glob = 'shellcheck-*/shellcheck',
  },
  ['yaml-language-server'] = {
    name = 'yaml-language-server',
    package = 'yaml-language-server',
    package_manager = 'bun',
    executable_path = join('node_modules', '.bin', 'yaml-language-server'),
  },
}

function M.path(...)
  return join(M.root, ...)
end

function M.bin_dir()
  return M.path('bin')
end

local function split_path(path)
  return vim.split(path or '', ':', { plain = true, trimempty = true })
end

local function contains_path(paths, target)
  for _, path in ipairs(paths) do
    if path == target then
      return true
    end
  end

  return false
end

local function update_path(dir, mode)
  mode = mode or 'prepend'
  if mode == 'skip' then
    return
  end

  local paths = split_path(vim.env.PATH)
  if contains_path(paths, dir) then
    return
  end

  if mode == 'prepend' then
    table.insert(paths, 1, dir)
  elseif mode == 'append' then
    table.insert(paths, dir)
  else
    error(('invalid PATH mode: %s'):format(mode))
  end

  vim.env.PATH = table.concat(paths, ':')
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

  return join(M.bin_dir(), tool.name)
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

function M.required_by_lsp_languages()
  local by_tool = {}
  local ok, lang = pcall(require, 'vimrc.lsp.lang')
  if not ok then
    return by_tool
  end

  for _, language_name in ipairs(lang.language_order or {}) do
    local language = lang.languages[language_name]
    if language and language.enabled and language.tools then
      for _, tool_name in ipairs(language.tools) do
        by_tool[tool_name] = by_tool[tool_name] or {}
        table.insert(by_tool[tool_name], language_name)
      end
    end
  end

  return by_tool
end

M.required_by_languages = M.required_by_lsp_languages

function M.default_tools()
  local selected = {}
  local required = M.required_by_lsp_languages()

  for name in pairs(required) do
    selected[name] = true
  end

  return selected
end

function M.setup(opts)
  opts = opts or {}

  update_path(M.bin_dir(), opts.PATH or 'prepend')
  require('vimrc.tools.commands').setup()
end

return M
