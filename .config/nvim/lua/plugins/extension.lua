---@type LazySpec
local spec = {
  -- yank
  {
    "gbprod/yanky.nvim",
    keys = {
      { "p",         "<Plug>(YankyPutAfter)",      mode = { "n", "v" } },
      { "P",         "<Plug>(YankyPutBefore)",     mode = { "n", "v" } },
      { "gp",        "<Plug>(YankyGPutAfter)",     mode = { "n", "v" } },
      { "gP",        "<Plug>(YankyGPutBefore)",    mode = { "n", "v" } },
      { "<c-p>",     "<Plug>(YankyPreviousEntry)", mode = { "n" } },
      { "<c-n>",     "<Plug>(YankyNextEntry)",     mode = { "n" } },
      { "<Leader>y", "<CMD>YankyRingHistory<CR>",  mode = { "n" } },
    },
    opts = {

    },
  },

  -- Diff
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
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
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    opts = {},
  }
}

return spec
