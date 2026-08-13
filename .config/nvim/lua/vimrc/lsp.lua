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
  -- codeAction requires `context`, which make_range_params() does not return.
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding) --[[@as lsp.CodeActionParams]]
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
    -- Client:exec_cmd() is async, which would let the write finish before the
    -- command applies, so the request stays synchronous here.
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
  vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
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

-- `g` stays a jump prefix: cursor motion goes there, everything else does not.
-- Jumps reuse the global defaults (`grr` `gri` `grt`) so no buffer-local `gr`
-- shadows them and makes every `gr` chord wait for 'timeoutlen'; `gd` and `gD`
-- have no default. The rest sits on <F2> and <LocalLeader>.
local function setup_keymaps(client, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  if client:supports_method('textDocument/definition') then
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  end
  if client:supports_method('textDocument/declaration') then
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  end
  if client:supports_method('textDocument/rename') then
    vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, bufopts)
  end
  if client:supports_method('textDocument/signatureHelp') then
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  end
  if client:supports_method('textDocument/documentSymbol') then
    vim.keymap.set('n', '<LocalLeader>s', vim.lsp.buf.document_symbol, bufopts)
  end
  if client:supports_method('workspace/symbol') then
    vim.keymap.set('n', '<LocalLeader>S', vim.lsp.buf.workspace_symbol, bufopts)
  end
  if client:supports_method('textDocument/codeAction') then
    vim.keymap.set('n', '<LocalLeader>c', vim.lsp.buf.code_action, bufopts)
  end
end

local highlight_group = vim.api.nvim_create_augroup('vimrc_lsp_highlight', { clear = true })

local function setup_document_highlight(client, bufnr)
  if not client:supports_method('textDocument/documentHighlight') then
    return
  end
  vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = bufnr })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = highlight_group,
    buffer = bufnr,
    desc = 'LSP document highlight',
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = highlight_group,
    buffer = bufnr,
    desc = 'LSP clear references',
    callback = vim.lsp.buf.clear_references,
  })
end

local function setup_codelens(client, bufnr)
  if not client:supports_method('textDocument/codeLens') then
    return
  end
  vim.lsp.codelens.enable(true, { bufnr = bufnr })
end

local function setup_inlay_hint(client, bufnr)
  if client:supports_method('textDocument/inlayHint') then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

local attach_group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = attach_group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil then
      return
    end
    setup_keymaps(client, ev.buf)
    setup_inlay_hint(client, ev.buf)
    setup_document_highlight(client, ev.buf)
    setup_codelens(client, ev.buf)
    setup_formatting(client, ev.buf)
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  group = attach_group,
  callback = function(ev)
    -- LspDetach also fires while the buffer is being wiped, when the
    -- buffer-scoped APIs below would throw.
    if not vim.api.nvim_buf_is_valid(ev.buf) then
      return
    end
    -- Another client may still serve the buffer, so the autocmds are only torn
    -- down once the detaching one is the last.
    local remaining = vim.tbl_filter(function(client)
      return client.id ~= ev.data.client_id
    end, vim.lsp.get_clients({ bufnr = ev.buf }))
    if #remaining > 0 then
      return
    end
    vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = ev.buf })
    vim.api.nvim_clear_autocmds({ group = format_group, buffer = ev.buf })
    vim.lsp.util.buf_clear_references(ev.buf)
  end,
})

vim.lsp.enable(servers)
