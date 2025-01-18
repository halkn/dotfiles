-- lsp config
local group = vim.api.nvim_create_augroup('vimrc_lspconfig', { clear = true })
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

    -- format
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set("n", "<LocalLeader>f", vim.lsp.buf.format, bufopts)
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
          if client.name ~= "ruff" then
            return
          end
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
      })
    end

    -- ruff
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
})

--setup
require("config.lspservers.luals")
require("config.lspservers.pyright")
require("config.lspservers.ruff")
require("config.lspservers.azure_pipelines_ls")
