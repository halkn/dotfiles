-- lsp config
local group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })
local format_group = vim.api.nvim_create_augroup('vimrc_lspformat', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    --mappings
    local bufopts = { noremap = true, silent = true, buffer = ev.buf }
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

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil then
      return
    end

    -- inlay hints
    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

    -- document highlight (cursorword)
    if client:supports_method('textDocument/documentHighlight') then
      local hl_group =
        vim.api.nvim_create_augroup('lsp_document_highlight_' .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = hl_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = hl_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- code lens
    if client:supports_method('textDocument/codeLens') then
      vim.keymap.set('n', 'grx', vim.lsp.codelens.run, bufopts)
      vim.lsp.codelens.enable(true, { bufnr = ev.buf })
    end

    -- format
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<LocalLeader>f', vim.lsp.buf.format, bufopts)
      vim.api.nvim_clear_autocmds({ group = format_group, buffer = ev.buf, event = 'BufWritePre' })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = format_group,
        buffer = ev.buf,
        desc = 'LSP format on save',
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
          if client.name == 'ruff' then
            vim.lsp.buf.code_action({
              context = {
                diagnostics = {},
                only = { 'source.organizeImports' },
              },
              apply = true,
            })
            vim.lsp.buf.code_action({
              context = {
                diagnostics = {},
                only = { 'source.fixAll' },
              },
              apply = true,
            })
          end
        end,
      })
    end

    -- ruff
    if client.name == 'ruff' then
      -- Disable hover when another Python type checker is attached.
      local pyright = vim.lsp.get_clients({ bufnr = ev.buf, name = 'pyright' })
      local ty = vim.lsp.get_clients({ bufnr = ev.buf, name = 'ty' })
      if #pyright > 0 or #ty > 0 then
        client.server_capabilities.hoverProvider = false
      end
    end
  end,
})

--setup
local lspservers = require('lang').lsp_servers()
vim.list_extend(lspservers, {
  -- "pyright",
  'ty',
  'ruff',
  'yamlls',
})
vim.lsp.enable(lspservers)
