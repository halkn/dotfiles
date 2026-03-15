local M = {}
-- hooks --------------------------------------------------------------------
M.hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  -- nvim-treesitter
  if name == 'nvim-treesitter' and (kind == "install" or kind == 'update') then
    if not ev.data.active then
      vim.cmd.packadd('nvim-treesitter')
    end
    vim.cmd('TSUpdate')
  end
end
vim.api.nvim_create_autocmd('PackChanged', { callback = M.hooks })

-- plugins ------------------------------------------------------------------
local au = vim.api.nvim_create_augroup("vimrc_augroup", { clear = true })
M.specs = {
  {
    src = "nvim-treesitter/nvim-treesitter",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end
  },
  {
    src = "navarasu/onedark.nvim",
    config = function()
      require('onedark').setup {
        style = 'darker'
      }
      require('onedark').load()
    end
  },
  {
    src = 'nvim-mini/mini.nvim',
    config = function()
      -- Appearance
      require('mini.cursorword').setup()
      require('mini.notify').setup()
      vim.notify = require('mini.notify').make_notify({})
      require('mini.statusline').setup()
      vim.opt.laststatus = 3
      vim.opt.cmdheight = 0
      require('mini.tabline').setup()

      -- Text editing
      require('mini.align').setup()
      require('mini.jump').setup()
      require('mini.operators').setup({
        replace = { prefix = 'R' },
        exchange = { prefix = 'g/' },
      })
      vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
      require('mini.pairs').setup({
        mappings = {
          ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
          ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
          ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
          ['<'] = { action = 'open', pair = '<>', neigh_pattern = '[^\\].' },
          [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
          [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
          ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
          ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[^\\].' },
          ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
          ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
          ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
        },
      })
      vim.keymap.set('i', '<C-h>', '<BS>')
      require('mini.splitjoin').setup({ mappings = { toggle = '<Leader>j' } })
      require('mini.surround').setup()

      -- General workflow
      require('mini.bufremove').setup()
      require('mini.diff').setup({
        view = {
          style = 'sign',
          signs = { add = '+', change = '~', delete = '-' }
        },
        mappings = {
          goto_first = '[C',
          goto_prev = '[c',
          goto_next = ']c',
          goto_last = ']C',
        }
      })
      require('mini.git').setup({})
      require('mini.files').setup()
      vim.api.nvim_create_user_command(
        'Files',
        function()
          MiniFiles.open()
        end,
        { desc = 'Open file explorer' }
      )
      require('mini.pick').setup({
        mappings = {
          caret_left = '<C-b>',
          caret_right = '<C-f>',
          delete_char = '<C-h>',
          scroll_left = '<NOP>',
          scroll_up = '<NOP>',
        },
      })
      vim.ui.select = MiniPick.ui_select
      -- mappings
      vim.keymap.set('n', '<Leader>f', function()
        MiniPick.builtin.files({ tool = 'rg' })
      end, { desc = 'mini.pick.files' })
      vim.keymap.set('n', '<Leader>b', function()
        MiniPick.builtin.buffers({})
      end, { desc = 'mini.pick.buffers' })
      vim.keymap.set('n', '<Leader>G', function()
        MiniPick.builtin.grep()
      end, { desc = 'mini.pick.grep' })
      require('mini.extra').setup()
      -- mappings
      vim.keymap.set('n', '<Leader>l', function()
        MiniExtra.pickers.buf_lines({ scope = 'current' })
      end, { desc = 'mini.pick.buffers' })
    end
  },
  {
    src = "monaqa/dial.nvim",
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
      vim.keymap.set({ "n", "x" }, "<C-a>", "<Plug>(dial-increment)")
      vim.keymap.set({ "n", "x" }, "<C-x>", "<Plug>(dial-decrement)")
      vim.keymap.set({ "n", "x" }, "g<C-a>", "g<Plug>(dial-increment)")
      vim.keymap.set({ "n", "x" }, "g<C-x>", "g<Plug>(dial-decrement)")
    end
  },
  {
    src = "gbprod/yanky.nvim",
    config = function()
      require("yanky").setup({})
      vim.keymap.set({ "n", "v" }, "p", "<Plug>(YankyPutAfter)")
      vim.keymap.set({ "n", "v" }, "P", "<Plug>(YankyPutBefore)")
      vim.keymap.set({ "n", "v" }, "gp", "<Plug>(YankyGPutAfter)")
      vim.keymap.set({ "n", "v" }, "gP", "<Plug>(YankyGPutBefore)")
      vim.keymap.set({ "n" }, "<c-p>", "<Plug>(YankyPreviousEntry)")
      vim.keymap.set({ "n" }, "<c-n>", "<Plug>(YankyNextEntry)")
      vim.keymap.set({ "n" }, "<Leader>y", "<CMD>YankyRingHistory<CR>")
    end
  },
  {
    src = "saghen/blink.cmp",
    version = "v1.9.1",
    config = function()
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
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
      })
    end
  },
  {
    src = "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      }

      -- local group_name = "vimrc_nvim-lint"
      -- vim.api.nvim_create_augroup(group_name, { clear = true })
      vim.api.nvim_create_autocmd("BufWritePost", {
        -- group = group_name,
        group = au,
        pattern = { "*.md" },
        callback = function()
          lint.try_lint()
        end
      })
    end
  },
  {
    src = "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
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
      })

      vim.api.nvim_create_autocmd("FileType", {
        -- group = group_name,
        group = au,
        pattern = { "markdown" },
        callback = function(ev)
          vim.keymap.set(
            "n",
            "<LocalLeader>f",
            function() require("conform").format({ bufnr = ev.buf }) end,
            { noremap = true, silent = true, buffer = ev.buf }
          )
        end
      })
    end
  },
  {
    src = "halkn/nvim-markview",
    config = function()
      require("markview").setup({
        keymaps = {
          toggle = "<localleader>p",
        },
      })
    end
  },
}

-- load plugins -------------------------------------------------------------
-- add plugins.
vim.pack.add(vim.tbl_map(function(p)
  return { src = 'https://github.com/' .. p.src, version = p.version }
end, M.specs))

-- load config.
for _, p in ipairs(M.specs) do
  if p.config then p.config() end
end

-- commands -----------------------------------------------------------------
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Update all plugins" })

vim.api.nvim_create_user_command("PackClean", function()
  local inactive = vim.iter(vim.pack.get())
      :filter(function(x) return not x.active end)
      :map(function(x) return x.spec.name end)
      :totable()

  if #inactive == 0 then
    vim.notify("Nothing to clean", vim.log.levels.INFO)
    return
  end

  vim.notify("Removing: " .. table.concat(inactive, ", "), vim.log.levels.INFO)
  vim.pack.del(inactive)
end, { desc = "Remove plugins not in vim.pack.add()" })

vim.api.nvim_create_user_command("PackReinstall", function(opts)
  local names = vim.split(opts.args, "%s+")
  local specs = vim.tbl_map(function(x) return x.spec end, vim.pack.get(names))

  vim.pack.del(names, { force = true })
  vim.pack.add(specs)

  vim.notify("Reinstalled: " .. table.concat(names, ", "), vim.log.levels.INFO)
end, {
  nargs = "+",
  desc = "Reinstall specified plugins",
  complete = function()
    return vim.tbl_map(function(x) return x.spec.name end, vim.pack.get())
  end,
})

return M
