--@type LazySpec
local spec = {
  -- colorscheme
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "kanagawa"
    end,
  },

  -- status line
  {
    'nvim-lualine/lualine.nvim',
    event = { "VeryLazy" },
    dependencies = { 'nvim-mini/mini.nvim' },
    opts = {
      options = {
        theme = 'auto',
        icons_enabled = true,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        globalstatus = true,
      },
      tabline = { lualine_a = { 'buffers' }, lualine_z = { 'tabs' }, }
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- "rcarriga/nvim-notify",
    }
  }

}

return spec
