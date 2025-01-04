---@type LazySpec
local spec = {
  -- git
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<Leader>gs", "<cmd>Neogit kind=floating<CR>" },
    },
    opts = {
      integrations = {
        telescope = true,
        diffview = true,
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    keys = {
      { "<Leader>gd", "<cmd>DiffviewOpen<CR>" },
      { "<Leader>gl", "<cmd>DiffviewFileHistory<CR>" },
      { "<Leader>gb", "<cmd>DiffviewFileHistory %<CR>" },
    },
    config = function()
      local actions = require("diffview.actions")
      local opts = {
        keymaps = {
          view = {
            { "n", "<tab>",   false },
            { "n", "<s-tab>", false },
            { "n", "<c-n>",   actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "<c-p>",   actions.select_prev_entry, { desc = "Open the diff for the prev file" } },
            { "n", "<cr>",    actions.goto_file_edit,    { desc = "Open the file in the previous tabpage" } },
            { "n", "q",       "<cmd>DiffviewClose<CR>",  { desc = "Close Diffview tabpage" } },
          },
          file_panel = {
            { "n", "<tab>",          false },
            { "n", "<s-tab>",        false },
            { "n", "<c-n>",          actions.select_next_entry,  { desc = "Open the diff for the next file" } },
            { "n", "<c-p>",          actions.select_prev_entry,  { desc = "Open the diff for the prev file" } },
            { "n", "j",              actions.select_next_entry,  { desc = "Open the diff for the next file" } },
            { "n", "k",              actions.select_prev_entry,  { desc = "Open the diff for the prev file" } },
            { "n", "<localleader>e", actions.goto_file_edit,     { desc = "Open the diff for the next file" } },
            { "n", "q",              "<cmd>DiffviewClose<CR>",   { desc = "Close Diffview tabpage" } },
            { "n", "?",              actions.help("file_panel"), { desc = "Open the help panel" } },
          },
          file_history_panel = {
            { "n", "<tab>",          false },
            { "n", "<s-tab>",        false },
            { "n", "<c-n>",          actions.select_next_entry,          { desc = "Open the diff for the next file" } },
            { "n", "<c-p>",          actions.select_prev_entry,          { desc = "Open the diff for the prev file" } },
            { "n", "j",              actions.select_next_entry,          { desc = "Open the diff for the next file" } },
            { "n", "k",              actions.select_prev_entry,          { desc = "Open the diff for the prev file" } },
            { "n", "<localleader>e", actions.goto_file_edit,             { desc = "Open the diff for the next file" } },
            { "n", "q",              "<cmd>DiffviewClose<CR>",           { desc = "Close Diffview tabpage" } },
            { "n", "?",              actions.help("file_history_panel"), { desc = "Open the help panel" } },
          },
        }
      }

      require("diffview").setup(opts)
    end
  },

  -- terminal
  {
    {
      'akinsho/toggleterm.nvim',
      version = "*",
      keys = {
        { "<C-t>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" } },
      },
      opts = {
        size = 20,
        direction = "float",
        float_opts = {
          border = 'double'
        },
        func_map = {
          drop = '<CR>',
        },
      },
    }
  },
}

return spec
