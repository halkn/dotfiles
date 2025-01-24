---@type LazySpec
local spec = {

  -- completion
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = "*",
    event = { "InsertEnter", "CmdlineEnter" },

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
      completion = {
        menu = {
          draw = {
            columns = {
              { "label",     "label_description", gap = 1 },
              { "kind_icon", "kind" },
            },
          },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    opts_extend = { "sources.default" },
  },

  -- lsp installer
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Linter/Formatter
  {
    "mfussenegger/nvim-lint",
    ft = { "markdown" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      }

      local group_name = "vimrc_nvim-lint"
      vim.api.nvim_create_augroup(group_name, { clear = true })
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group_name,
        pattern = { "*.md" },
        callback = function()
          lint.try_lint()
        end
      })
    end
  },
  {
    "stevearc/conform.nvim",
    ft = { "markdown" },
    opts = {
      formatters_by_ft = {
        markdown = { "markdownlint-cli2" }
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
      format_after_save = {
        lsp_format = "fallback",
      },
    },
    config = function(_, opts)
      local conform = require("conform")

      local group_name = "vimrc_cnform"
      vim.api.nvim_create_augroup(group_name, { clear = true })

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.md" },
        callback = function(ev)
          conform.format({ bufnr = ev.buf })
        end
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = group_name,
        pattern = { "markdown" },
        callback = function(ev)
          vim.keymap.set(
            "n",
            "<LocalLeader>f",
            function() conform.format({ bufnr = ev.buf }) end,
            { noremap = true, silent = true, buffer = ev.buf }
          )
        end
      })

      conform.setup(opts)
    end
  }
}

return spec
