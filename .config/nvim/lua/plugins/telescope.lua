local map = vim.keymap.set
local kopts = { noremap = true, silent = true }

local actions = require("telescope.actions")

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Telescope",
  init = function()
      map("n", "<Leader>f", "<cmd>Telescope find_files<CR>", kopts)
      map("n", "<Leader>b", "<cmd>Telescope buffers<CR>", kopts)
      map("n", "<Leader>g", "<cmd>Telescope live_grep<CR>", kopts)
  end,
  config = function()
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
          },
        },
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
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = {
          "truncate",
          filename_first = { reverse_directories = false },
        },
        color_devicons = true,
        use_less = true,
      },
      pickers = {
        find_files = {
          find_command = {"rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
    })
  end
}
