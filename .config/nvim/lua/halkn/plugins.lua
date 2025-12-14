local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

------------------------------------------------------------------------------
-- colorscheme
------------------------------------------------------------------------------
now(function()
  add({ source = "rebelot/kanagawa.nvim" })
  vim.cmd.colorscheme "kanagawa"
end)

------------------------------------------------------------------------------
-- util
------------------------------------------------------------------------------
later(function()
  -- dial.nvim
  add({ source = "monaqa/dial.nvim" })
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
    }
  })
  vim.keymap.set({ "n", "v" }, "<C-a>", "<Plug>(dial-increment)")
  vim.keymap.set({ "n", "v" }, "<C-x>", "<Plug>(dial-decrement)")
  vim.keymap.set({ "n", "v" }, "g<C-a>", "g<Plug>(dial-increment)")
  vim.keymap.set({ "n", "v" }, "g<C-x>", "g<Plug>(dial-decrement)")

  -- yanky.nvim
  add({ source = "gbprod/yanky.nvim" })
  require("yanky").setup()
  vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
  vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
  vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
  vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
  vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
  vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")
  vim.keymap.set("n", "<Leader>y", "<CMD>YankyRingHistory<CR>")

  -- toggleterm.nvim
  add({ source = "akinsho/toggleterm.nvim" })
  require("toggleterm").setup()
  vim.keymap.set({ "n", "t" }, "<C-t>", "<CMD>ToggleTerm direction=float<CR>")
end)

------------------------------------------------------------------------------
-- completion
------------------------------------------------------------------------------
now(function()
  add({
    source = "saghen/blink.cmp",
    depends = { "rafamadriz/friendly-snippets" },
    checkout = "v1.8.0", -- check releases for latest tag
  })
  require("blink.cmp").setup({
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
    cmdline = {
      keymap = { preset = 'inherit' },
      completion = { menu = { auto_show = true } },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  })
end)

------------------------------------------------------------------------------
-- git
------------------------------------------------------------------------------
later(function()
  add({
    source = "esmuellert/vscode-diff.nvim",
    depends = { "MunifTanjim/nui.nvim" }
  })
  require("vscode-diff").setup({
    keymaps = {
      view = {
        quit = "q",                -- Close diff tab
        toggle_explorer = "<C-e>", -- Toggle explorer visibility (explorer mode only)
        next_hunk = "]c",          -- Jump to next change
        prev_hunk = "[c",          -- Jump to previous change
        next_file = "<C-n>",       -- Next file in explorer mode
        prev_file = "<C-p>",       -- Previous file in explorer mode
      },
      explorer = {
        select = "<CR>", -- Open diff for selected file
        hover = "K",     -- Show file diff preview
        refresh = "R",   -- Refresh git status
      },
    },
  })
  vim.keymap.set({ "n" }, "<Leader>gd", "<CMD>CodeDiff<CR>")
end)

------------------------------------------------------------------------------
-- Lint/Format
------------------------------------------------------------------------------
later(function()
  add({ source = "mfussenegger/nvim-lint" })
  local lint = require("lint")
  lint.linters_by_ft = {
    markdown = { "markdownlint-cli2" },
  }

  local group_name = "vimrc_lint"
  vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group_name,
    pattern = { "*.md" },
    callback = function()
      lint.try_lint()
    end
  })


  add({ source = "stevearc/conform.nvim" })
  local opts = {
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
  }
  local conform = require("conform")

  -- local group_name = "vimrc_cnform"
  vim.api.nvim_create_augroup(group_name, { clear = true })

  -- vim.api.nvim_create_autocmd("BufWritePost", {
  --   pattern = { "*.md" },
  --   callback = function(ev)
  --     conform.format({ bufnr = ev.buf })
  --   end
  -- })
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

  -- conform.setup(opts)
  vim.opt.fixendofline = true
end)

------------------------------------------------------------------------------
-- markdown
------------------------------------------------------------------------------
later(function()
  add({ source = "yousefhadder/markdown-plus.nvim", })
  require("markdown-plus").setup({
    features = {
      list_management = true,  -- default: true (list auto-continue / indent / renumber / checkboxes)
      text_formatting = false, -- default: true (bold/italic/strike/code + clear)
      headers_toc = false,     -- default: true (headers nav + TOC generation & window)
      links = true,            -- default: true (insert/edit/convert/reference links)
      images = true,           -- default: true (insert/edit image links + toggle link/image)
      quotes = true,           -- default: true (blockquote toggle)
      callouts = true,         -- default: true (GFM callouts/admonitions)
      code_block = true,       -- default: true (visual selection -> fenced block)
      table = true,            -- default: true (table creation & editing)
      footnotes = true,        -- default: true (footnote insertion/navigation/listing)
    },
    keymaps = {
      enabled = false, -- Disable all default keymaps
    },
    table = {
      auto_format = true,              -- default: true  auto format table after operations
      default_alignment = "left",      -- default: "left"  alignment used for new columns
      confirm_destructive = true,      -- default: true  confirm before transpose/sort operations
      keymaps = {                      -- Table-specific keymaps (prefix based)
        enabled = true,                -- default: true  provide table keymaps
        prefix = "<localleader>t",     -- default: "<leader>t"  prefix for table ops
        insert_mode_navigation = true, -- default: true  Alt+hjkl cell navigation
      },
    },
  })
  add({ source = 'brianhuster/live-preview.nvim', })
  require('livepreview.config').set()

  local group_name = "vimrc_markdown"
  vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group_name,
    pattern = "markdown",
    callback = function()
      local opts = { silent = false, noremap = true, buffer = true }
      vim.keymap.set('n', '<LocalLeader>p', '<CMD>LivePreview start<CR>', opts)
      vim.keymap.set("i", "<CR>", "<Plug>(MarkdownPlusListEnter)", opts)
      vim.keymap.set("i", "<C-h>", "<Plug>(MarkdownPlusListBackspace)", opts)
      vim.keymap.set("i", "<BS>", "<Plug>(MarkdownPlusListBackspace)", opts)
      vim.keymap.set("n", "o", "<Plug>(MarkdownPlusNewListItemBelow)", opts)
      vim.keymap.set("n", "O", "<Plug>(MarkdownPlusNewListItemAbove)", opts)
      vim.keymap.set("n", "<localleader>l", "<Plug>(MarkdownPlusInsertLink)", opts)
      vim.keymap.set("v", "<localleader>l", "<Plug>(MarkdownPlusSelectionToLink)", opts)
      vim.keymap.set("n", "<localleader>i", "<Plug>(MarkdownPlusInsertImage)", opts)
      vim.keymap.set("v", "<localleader>i", "<Plug>(MarkdownPlusSelectionToImage)", opts)
    end
  })
end)
