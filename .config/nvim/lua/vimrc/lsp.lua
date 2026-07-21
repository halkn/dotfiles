local servers = {
  'pyright',
  'ruff',
  'emmylua_ls',
  'shuck',
  'rumdl',
  'ryl',
}

-- formatting

local format_group = vim.api.nvim_create_augroup('vimrc_lspformat', { clear = true })

local function apply_ruff_action(client, bufnr, kind)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { diagnostics = {}, only = { kind } }

  local response, err = client:request_sync('textDocument/codeAction', params, 1000, bufnr)
  if err then
    vim.notify(('[ruff] %s: %s'):format(kind, err), vim.log.levels.WARN)
    return
  end

  local action = response and response.result and response.result[1]
  if not action then
    return
  end
  if not action.edit and not action.command and client:supports_method('codeAction/resolve') then
    local resolved = client:request_sync('codeAction/resolve', action, 1000, bufnr)
    action = resolved and resolved.result or action
  end
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    local command = type(action.command) == 'table' and action.command or action
    client:request_sync('workspace/executeCommand', {
      command = command.command,
      arguments = command.arguments,
    }, 1000, bufnr)
  end
end

local function format_buffer(bufnr)
  local ruff = vim.lsp.get_clients({
    bufnr = bufnr,
    name = 'ruff',
    method = 'textDocument/codeAction',
  })[1]
  if ruff then
    apply_ruff_action(ruff, bufnr, 'source.organizeImports.ruff')
    apply_ruff_action(ruff, bufnr, 'source.fixAll.ruff')
  end
  vim.lsp.buf.format({ bufnr = bufnr })
end

local function setup_formatting(client, bufnr)
  if not client:supports_method('textDocument/formatting') then
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

vim.lsp.enable(servers)
