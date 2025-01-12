-- lsp config
local group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true })
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
    -- if client ~= nil and client.name ~= "pyright" then
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

-- diagnostic config
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
  },
})
-- diagnostic autocmd for mappings
vim.api.nvim_create_autocmd('DiagnosticChanged', {
  group = group,
  callback = function(ev)
    --mappings
    local bufopts = { noremap = true, silent = true, buffer = ev.buf }
    vim.keymap.set("n", "<LocalLeader>e", vim.diagnostic.open_float, bufopts)
    vim.keymap.set("n", "<LocalLeader>d", vim.diagnostic.setloclist, bufopts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, bufopts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, bufopts)
  end,
})

--setup
require("lspconfigs.luals")
require("lspconfigs.pyright")
require("lspconfigs.ruff")
