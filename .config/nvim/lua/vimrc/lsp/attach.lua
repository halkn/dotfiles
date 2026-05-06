local formatting = require('vimrc.lsp.formatting')
local keymaps = require('vimrc.lsp.keymaps')

local M = {}

local group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })

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

function M.setup()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(ev)
      keymaps.setup(ev.buf)

      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client == nil then
        return
      end

      setup_inlay_hint(client, ev.buf)
      setup_document_highlight(client, ev.buf)
      setup_codelens(client, ev.buf)
      formatting.setup(client, ev.buf)
      adjust_ruff_capabilities(client, ev.buf)
    end,
  })
end

return M
