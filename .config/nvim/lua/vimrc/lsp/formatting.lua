local lang = require('vimrc.lsp.lang')

local M = {}

local format_group = vim.api.nvim_create_augroup('vimrc_lspformat', { clear = true })

local function format_client_name(bufnr)
  return lang.format_client_name(bufnr)
end

function M.is_format_client(client, bufnr)
  local name = format_client_name(bufnr)
  return name ~= nil and client.name == name
end

local function apply_format_actions(client, bufnr)
  if client.name ~= 'ruff' then
    return
  end

  vim.lsp.buf.code_action({
    bufnr = bufnr,
    context = {
      diagnostics = {},
      only = { 'source.organizeImports' },
    },
    apply = true,
  })
  vim.lsp.buf.code_action({
    bufnr = bufnr,
    context = {
      diagnostics = {},
      only = { 'source.fixAll' },
    },
    apply = true,
  })
end

function M.format_buffer(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    filter = function(client)
      return M.is_format_client(client, bufnr)
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

function M.setup(client, bufnr)
  if not M.is_format_client(client, bufnr) then
    return
  end

  vim.keymap.set('n', '<LocalLeader>f', function()
    M.format_buffer(bufnr)
  end, { noremap = true, silent = true, buffer = bufnr })

  vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr, event = 'BufWritePre' })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = format_group,
    buffer = bufnr,
    desc = 'LSP format on save',
    callback = function()
      M.format_buffer(bufnr)
    end,
  })
end

return M
