local M = {}

M.language_order = {
  'python',
  'lua',
  'zsh',
  'bash',
  'markdown',
  'yaml',
}

M.languages = {
  python = {
    enabled = true,
    filetypes = { 'python' },
    lsp = { 'ty', 'ruff' },
    format = {
      client = 'ruff',
    },
  },
  lua = {
    enabled = true,
    filetypes = { 'lua' },
    lsp = { 'luals', 'efm' },
    tools = { 'lua-language-server', 'stylua', 'efm-langserver' },
    format = {
      client = 'efm',
      tool = 'stylua',
    },
  },
  zsh = {
    enabled = true,
    filetypes = { 'zsh' },
    tools = { 'shfmt', 'efm-langserver' },
    lsp = { 'efm' },
    format = {
      client = 'efm',
      tool = 'shfmt',
    },
  },
  bash = {
    enabled = false,
    filetypes = { 'bash', 'sh' },
    lsp = { 'bashls' },
    tools = { 'shfmt', 'shellcheck' },
    format = {
      client = 'bashls',
    },
  },
  markdown = {
    enabled = true,
    filetypes = { 'markdown' },
    lsp = { 'rumdl' },
    format = {
      client = 'rumdl',
    },
  },
  yaml = {
    enabled = true,
    filetypes = { 'yaml' },
    lsp = { 'yamlls' },
    tools = { 'yaml-language-server' },
    format = {
      client = 'yamlls',
    },
  },
}

local function enabled_languages()
  local languages = {}
  for _, name in ipairs(M.language_order) do
    local language = M.languages[name]
    if language and language.enabled then
      table.insert(languages, { name = name, config = language })
    end
  end

  return languages
end

function M.lsp_servers()
  local servers = {}
  local seen = {}
  for _, language in ipairs(enabled_languages()) do
    language = language.config
    for _, server in ipairs(language.lsp or {}) do
      if not seen[server] then
        table.insert(servers, server)
        seen[server] = true
      end
    end
  end

  return servers
end

function M.lsp_filetypes(server_name)
  local filetypes = {}
  local seen = {}
  for _, language in ipairs(enabled_languages()) do
    language = language.config
    if vim.tbl_contains(language.lsp or {}, server_name) then
      for _, filetype in ipairs(language.filetypes or {}) do
        if not seen[filetype] then
          table.insert(filetypes, filetype)
          seen[filetype] = true
        end
      end
    end
  end

  table.sort(filetypes)
  return filetypes
end

function M.format_tools_by_ft(client_name)
  local tools = {}
  for _, language in ipairs(enabled_languages()) do
    language = language.config
    local format = language.format
    if format and format.client == client_name and format.tool then
      for _, filetype in ipairs(language.filetypes or {}) do
        tools[filetype] = format.tool
      end
    end
  end

  return tools
end

function M.language_for_filetype(filetype)
  for _, language in ipairs(enabled_languages()) do
    language = language.config
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

  local format = language.format
  if format == nil then
    return nil
  end

  return format.client
end

return M
