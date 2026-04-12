-- lsp config
local group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })
local format_group = vim.api.nvim_create_augroup('vimrc_lspformat', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    --mappings
    local bufopts = { noremap = true, silent = true, buffer = ev.buf }
    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "<LocalLeader>s", vim.lsp.buf.document_symbol, bufopts)
    vim.keymap.set("n", "<LocalLeader>S", vim.lsp.buf.workspace_symbol, bufopts)
    vim.keymap.set("n", "<LocalLeader>c", vim.lsp.buf.code_action, bufopts)

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
      local hl_group = vim.api.nvim_create_augroup('lsp_document_highlight_' .. ev.buf, { clear = true })
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

    -- format
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set("n", "<LocalLeader>f", vim.lsp.buf.format, bufopts)
      vim.api.nvim_clear_autocmds({ group = format_group, buffer = ev.buf, event = "BufWritePre" })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_group,
        buffer = ev.buf,
        desc = "LSP format on save",
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
          if client.name == "ruff" then
            vim.lsp.buf.code_action({
              context = {
                diagnostics = {},
                only = { "source.organizeImports" },
              },
              apply = true,
            })
            vim.lsp.buf.code_action({
              context = {
                diagnostics = {},
                only = { "source.fixAll" },
              },
              apply = true,
            })
          end
        end
      })
    end

    -- ruff
    if client.name == 'ruff' then
      -- Disable hover only when Pyright is attached for this buffer.
      local pyright = vim.lsp.get_clients({ bufnr = ev.buf, name = "pyright" })
      if #pyright > 0 then
        client.server_capabilities.hoverProvider = false
      end
    end
  end,
})

-- lsp progress
local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
vim.api.nvim_create_autocmd('LspProgress', {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end
    local value = ev.data.params.value
    if type(value) ~= 'table' then return end

    local msg = ''
    if value.title then msg = value.title end
    if value.message then msg = msg .. ' ' .. value.message end
    if value.percentage then msg = msg .. string.format(' (%d%%)', value.percentage) end

    local done = value.kind == 'end'
    local icon = done and '  '
        or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]

    vim.notify(icon .. ' ' .. vim.trim(msg), vim.log.levels.INFO, {
      id = 'lsp_progress_' .. client.id,
      title = client.name,
      timeout = done and 1000 or false,
    })
  end,
})

--setup
local lspservers = {
  "luals",
  -- "pyright",
  "ty",
  "ruff",
  "azure_pipelines_ls",
  -- "bashls",
}
vim.lsp.enable(lspservers)
