---@type LazySpec
local spec = {

  -- telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
    },
    keys = {
      { "<Leader>f", "<cmd>Telescope find_files<CR>" },
      { "<Leader>b", "<cmd>Telescope buffers<CR>" },
      { "<Leader>g", "<cmd>Telescope live_grep<CR>" },
    },
    opts = {
      defaults = {
        sorting_strategy = "ascending",
        layout_strategy = "flex",
        layout_config = {
          width = 0.9,
          height = 0.9,
          prompt_position = "top",
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob",
          "!**/.git/*",
          "--trim"
        },
        path_display = {
          "truncate",
          filename_first = { reverse_directories = false },
        },
        color_devicons = true,
        use_less = true,
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
    },
    config = function(_, opts)
      local actions = require("telescope.actions")
      local layout = require("telescope.actions.layout")
      local mappings = {
        i = {
          ["<esc>"] = actions.close,
          ["<M-p>"] = layout.toggle_preview,
          ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
        },
      }
      opts.defaults.mappings = mappings
      require('telescope').setup(opts)
      require('telescope').load_extension('fzy_native')
    end
  },
}

return spec
