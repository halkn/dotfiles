local M = {}

M.languages = {
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

function M.format_filetypes()
  local filetypes = vim.tbl_keys(M.formatters_by_ft())
  table.sort(filetypes)
  return filetypes
end

return M
