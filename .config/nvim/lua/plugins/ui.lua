local map = vim.keymap.set
local kopts = { noremap = true, silent = true }

return {
  -- colorscheme
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme nightfox]])
    end,
  },
  -- status line
  {
    'nvim-lualine/lualine.nvim',
    event = { "BufReadPre", "BufWinEnter", "BufEnter" },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup{
        options = {
          icons_enabled = true,
          theme = 'nightfox',
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          always_show_tabline = true,
          globalstatus = false,
          refresh = {
            statusline = 100,
            tabline = 100,
            winbar = 100,
          }
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      }
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    init = function()
        map("n", "<Leader>e", "<cmd>Neotree toggle<CR>", kopts)
    end,
    config = function()
      require("neo-tree").setup({
        window = {
            position = "float",
        },
        enable_git_status = true,
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_by_name = {
                ".DS_Store",
            },
          },
        },
        follow_current_file = {
            enabled = true,
        },
        never_show = {},
      })
    end
  }
}
