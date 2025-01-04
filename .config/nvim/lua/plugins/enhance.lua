---@type LazySpec
local spec = {

  -- f motion
  {
    "hrsh7th/vim-eft",
    keys = {
      { "f", "<Plug>(eft-f)",      mode = { "n", "x", "o" } },
      { "F", "<Plug>(eft-F)",      mode = { "n", "x", "o" } },
      { "t", "<Plug>(eft-t)",      mode = { "n", "x", "o" } },
      { "T", "<Plug>(eft-T)",      mode = { "n", "x", "o" } },
      { ";", "<Plug>(eft-repeat)", mode = { "n", "x", "o" } },
    },
  },

  -- textobject Replace
  {
    "kana/vim-operator-replace",
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { "R", "<Plug>(operator-replace)", mode = "" },
    },
  },

  -- surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {
      keymaps = {
        -- insert = "<C-g>s",
        -- insert_line = "<C-g>S",
        normal = "sa",
        -- normal_cur = "yss",
        -- normal_line = "yS",
        -- normal_cur_line = "ySS",
        visual = "sa",
        -- visual_line = "gS",
        delete = "sd",
        change = "sr",
        -- change_line = "cS",
      },
    },
  },

  -- increment/decrement <C-a>/<C-x>
  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>",  "<Plug>(dial-increment)",  mode = { "n", "v" } },
      { "<C-x>",  "<Plug>(dial-decrement)",  mode = { "n", "v" } },
      { "g<C-a>", "g<Plug>(dial-increment)", mode = { "n", "v" } },
      { "g<C-x>", "g<Plug>(dial-decrement)", mode = { "n", "v" } },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.alias.bool,
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%H:%M"],
          augend.date.alias["%Y年%-m月%-d日"],
          augend.date.alias["%Y年%-m月%-d日(%ja)"],
          augend.constant.alias.ja_weekday,
          augend.constant.alias.ja_weekday_full,
        },
      })
    end
  },

  -- insert mode
  {
    "hrsh7th/nvim-insx",
    event = "InsertEnter",
    config = function()
      require('insx.preset.standard').setup()
      vim.keymap.set('i', '<C-h>', "<BS>", { silent = false, remap = true })
    end
  },

  -- splitting/joining
  {
    "Wansmer/treesj",
    keys = {
      { "<Leader>j", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },

  -- quickfix
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      auto_resize_height = true,
      func_map = {
        openc = "<CR>",
        split = "<C-s>",
        tabdrop = "<C-t>",
        stoggleup = "S",
        stoggledown = "s",
        stogglevm = "s",
      },
    },
  }
}

return spec
