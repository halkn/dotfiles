local M = {}

M.languages = {
  python = {
    enabled = true,
    filetypes = { 'python' },
    lsp = { 'ty', 'ruff' },
    format_client = 'ruff',
    formatters_by_ft = {},
    linters_by_ft = {},
  },
  lua = {
    enabled = true,
    filetypes = { 'lua' },
    lsp = { 'luals' },
    tools = { 'lua-language-server', 'stylua' },
    formatters_by_ft = {
      lua = { 'stylua' },
    },
    linters_by_ft = {},
  },
  zsh = {
    enabled = true,
    filetypes = { 'zsh' },
    tools = { 'shfmt' },
    formatters_by_ft = {
      zsh = { 'shfmt' },
    },
    linters_by_ft = {
      zsh = { 'zsh' },
    },
  },
  bash = {
    enabled = false,
    filetypes = { 'bash', 'sh' },
    lsp = { 'bashls' },
    tools = { 'shfmt', 'shellcheck' },
    format_client = 'bashls',
    formatters_by_ft = {},
    linters_by_ft = {},
  },
  markdown = {
    enabled = true,
    filetypes = { 'markdown' },
    lsp = { 'rumdl' },
    format_client = 'rumdl',
    formatters_by_ft = {},
    linters_by_ft = {},
  },
  yaml = {
    enabled = true,
    filetypes = { 'yaml' },
    lsp = { 'yamlls' },
    tools = { 'yaml-language-server' },
    format_client = 'yamlls',
    formatters_by_ft = {},
    linters_by_ft = {},
  },
}

local function enabled_languages()
  return vim.iter(M.languages):filter(function(_, language)
    return language.enabled
  end)
end

function M.lsp_servers()
  local servers = {}
  enabled_languages():each(function(_, language)
    vim.list_extend(servers, language.lsp or {})
  end)

  return servers
end

function M.formatters_by_ft()
  local by_ft = {}
  enabled_languages():each(function(_, language)
    by_ft = vim.tbl_deep_extend('force', by_ft, language.formatters_by_ft or {})
  end)

  return by_ft
end

function M.linters_by_ft()
  local by_ft = {}
  enabled_languages():each(function(_, language)
    by_ft = vim.tbl_deep_extend('force', by_ft, language.linters_by_ft or {})
  end)

  return by_ft
end

function M.language_for_filetype(filetype)
  for _, language in pairs(M.languages) do
    if language.enabled then
      for _, language_filetype in ipairs(language.filetypes or {}) do
        if language_filetype == filetype then
          return language
        end
      end
    end
  end

  return nil
end

function M.format_client_name(bufnr)
  local language = M.language_for_filetype(vim.bo[bufnr].filetype)
  if language == nil then
    return nil
  end

  return language.format_client
end

function M.format_filetypes()
  local filetypes = vim.tbl_keys(M.formatters_by_ft())
  table.sort(filetypes)
  return filetypes
end

return M
