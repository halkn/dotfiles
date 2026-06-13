---@class vimrc.lsp.FormatConfig
---@field client string

---@class vimrc.lsp.LanguageConfig
---@field enabled boolean
---@field filetypes string[]
---@field lsp? string[]
---@field format? vimrc.lsp.FormatConfig

local language_order = {
  'python',
  'lua',
  'zsh',
  'bash',
  'markdown',
  'yaml',
}

---@type table<string, vimrc.lsp.LanguageConfig>
local languages = {
  python = {
    enabled = true,
    filetypes = { 'python' },
    lsp = { 'ty', 'ruff' },
    format = { client = 'ruff' },
  },
  lua = {
    enabled = true,
    filetypes = { 'lua' },
    lsp = { 'luals', 'efm' },
    format = { client = 'efm' },
  },
  zsh = {
    enabled = true,
    filetypes = { 'zsh' },
    lsp = { 'efm' },
    format = { client = 'efm' },
  },
  bash = {
    enabled = false,
    filetypes = { 'bash', 'sh' },
    lsp = { 'bashls' },
    format = { client = 'bashls' },
  },
  markdown = {
    enabled = true,
    filetypes = { 'markdown' },
    lsp = { 'rumdl' },
    format = { client = 'rumdl' },
  },
  yaml = {
    enabled = true,
    filetypes = { 'yaml' },
    lsp = { 'efm' },
    format = { client = 'efm' },
  },
}

local function enabled_languages()
  local result = {}
  for _, name in ipairs(language_order) do
    local lang = languages[name]
    if lang and lang.enabled then
      table.insert(result, lang)
    end
  end
  return result
end

local function lsp_servers()
  local servers = {}
  local seen = {}
  for _, lang in ipairs(enabled_languages()) do
    for _, server in ipairs(lang.lsp or {}) do
      if not seen[server] then
        table.insert(servers, server)
        seen[server] = true
      end
    end
  end
  return servers
end

local function format_client_name(bufnr)
  local ft = vim.bo[bufnr].filetype
  for _, lang in ipairs(enabled_languages()) do
    if vim.tbl_contains(lang.filetypes, ft) then
      return lang.format and lang.format.client or nil
    end
  end
  return nil
end

-- formatting

local format_group = vim.api.nvim_create_augroup('vimrc_lspformat', { clear = true })

local function is_format_client(client, bufnr)
  local name = format_client_name(bufnr)
  return name ~= nil and client.name == name
end

local function apply_format_actions(client, bufnr)
  if client.name ~= 'ruff' then
    return
  end
  vim.lsp.buf.code_action({
    bufnr = bufnr,
    context = { diagnostics = {}, only = { 'source.organizeImports' } },
    apply = true,
  })
  vim.lsp.buf.code_action({
    bufnr = bufnr,
    context = { diagnostics = {}, only = { 'source.fixAll' } },
    apply = true,
  })
end

local function format_buffer(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    filter = function(client)
      return is_format_client(client, bufnr)
    end,
  })
  local client_name = format_client_name(bufnr)
  if client_name == nil then
    return
  end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = client_name })) do
    apply_format_actions(client, bufnr)
  end
end

local function setup_formatting(client, bufnr)
  if not is_format_client(client, bufnr) then
    return
  end
  vim.keymap.set('n', '<LocalLeader>f', function()
    format_buffer(bufnr)
  end, { noremap = true, silent = true, buffer = bufnr })
  vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr, event = 'BufWritePre' })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = format_group,
    buffer = bufnr,
    desc = 'LSP format on save',
    callback = function()
      format_buffer(bufnr)
    end,
  })
end

-- attach

local function setup_keymaps(bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', 'grt', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<LocalLeader>s', vim.lsp.buf.document_symbol, bufopts)
  vim.keymap.set('n', '<LocalLeader>S', vim.lsp.buf.workspace_symbol, bufopts)
  vim.keymap.set('n', '<LocalLeader>c', vim.lsp.buf.code_action, bufopts)
end

local function setup_document_highlight(client, bufnr)
  if not client:supports_method('textDocument/documentHighlight') then
    return
  end
  local hl_group = vim.api.nvim_create_augroup('lsp_document_highlight_' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = hl_group,
    buffer = bufnr,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = hl_group,
    buffer = bufnr,
    callback = vim.lsp.buf.clear_references,
  })
end

local function setup_codelens(client, bufnr)
  if not client:supports_method('textDocument/codeLens') then
    return
  end
  vim.keymap.set(
    'n',
    'grx',
    vim.lsp.codelens.run,
    { noremap = true, silent = true, buffer = bufnr }
  )
  vim.lsp.codelens.enable(true, { bufnr = bufnr })
end

local function setup_inlay_hint(client, bufnr)
  if client:supports_method('textDocument/inlayHint') then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

local function adjust_ruff_capabilities(client, bufnr)
  if client.name ~= 'ruff' then
    return
  end
  -- Disable hover when another Python type checker is attached.
  local pyright = vim.lsp.get_clients({ bufnr = bufnr, name = 'pyright' })
  local ty = vim.lsp.get_clients({ bufnr = bufnr, name = 'ty' })
  if #pyright > 0 or #ty > 0 then
    client.server_capabilities.hoverProvider = false
  end
end

local attach_group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = attach_group,
  callback = function(ev)
    setup_keymaps(ev.buf)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil then
      return
    end
    setup_inlay_hint(client, ev.buf)
    setup_document_highlight(client, ev.buf)
    setup_codelens(client, ev.buf)
    setup_formatting(client, ev.buf)
    adjust_ruff_capabilities(client, ev.buf)
  end,
})

vim.lsp.enable(lsp_servers())
