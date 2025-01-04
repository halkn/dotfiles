-- lsp config
local group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    --mappings
    local bufopts = { noremap = true, silent = true, buffer = ev.buf }
    vim.keymap.set("n", "<LocalLeader>f", vim.lsp.buf.format, bufopts)
    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "<LocalLeader>s", vim.lsp.buf.document_symbol, bufopts)
    vim.keymap.set("n", "<LocalLeader>S", vim.lsp.buf.workspace_symbol, bufopts)
    vim.keymap.set("n", "<LocalLeader>e", vim.diagnostic.open_float, bufopts)
    vim.keymap.set("n", "<LocalLeader>d", vim.diagnostic.setloclist, bufopts)
    vim.keymap.set("n", "<LocalLeader>c", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client ~= nil then
      if client:supports_method('textDocument/formatting') then
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = group,
          buffer = ev.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
          end
        })
      end
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


---@type LazySpec
local spec = {

  -- completion
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = "*",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'super-tab',
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },
      signature = { enabled = true },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    -- opts_extend = { "sources.default" },
  },
  -- setup bultin lsp client
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    event = "VeryLazy",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
                pathStrict = true,
                path = { "?.lua", "?/init.lua" },
              },
              diagnostics = {
                globals = { "vim" },
              },
              format = {
                enable = true,
                defaultConfig = {
                  indent_style = "space",
                  indent_size = "2",
                },
                completion = {
                  callSnippet = 'Disable',
                  keywordSnippet = 'Disable',
                }
              },
              workspace = {
                library = {
                  vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "/lazy/lazy.nvim/lua"),
                  vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "lua"),
                  vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
                  "${3rd}/luv/library",
                  "${3rd}/busted/library",
                  "${3rd}/luassert/library",
                }
              },
            },
          },
        }
      }
    },
    config = function(_, opts)
      local lspconfig = require('lspconfig')

      -- setup each server
      for server, settings in pairs(opts.servers) do
        settings.capabilities = require('blink.cmp').get_lsp_capabilities(settings.capabilities)
        lspconfig[server].setup(settings)
      end
    end,
  },

  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {},
  },
}

return spec
