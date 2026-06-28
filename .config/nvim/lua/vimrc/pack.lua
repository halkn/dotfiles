local M = {}
-- hooks --------------------------------------------------------------------
M.hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  -- nvim-treesitter
  if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
    if not ev.data.active then
      vim.cmd.packadd('nvim-treesitter')
    end
    vim.cmd('TSUpdate')
  end
end
vim.api.nvim_create_autocmd('PackChanged', { callback = M.hooks })

-- plugins ------------------------------------------------------------------
local plugs = {
  {
    src = 'rebelot/kanagawa.nvim',
    config = function()
      vim.cmd.colorscheme('kanagawa')
    end,
  },
  {
    src = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup()
    end,
  },
  {
    src = 'nvim-treesitter/nvim-treesitter',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('vim-treesitter-start', {}),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
  {
    src = 'saghen/blink.cmp',
    version = 'v1.10.2',
    config = function()
      require('blink.cmp').setup({
        keymap = {
          preset = 'super-tab',
        },
        cmdline = { enabled = true },
        appearance = {
          nerd_font_variant = 'mono',
        },
        signature = { enabled = true },
        completion = {
          documentation = { auto_show = true, auto_show_delay_ms = 500 },
        },
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
      })
    end,
  },
  {
    src = 'monaqa/dial.nvim',
    config = function()
      local augend = require('dial.augend')
      require('dial.config').augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.alias.bool,
          augend.date.alias['%Y/%m/%d'],
          augend.date.alias['%Y-%m-%d'],
          augend.date.alias['%H:%M'],
          augend.date.alias['%Y年%-m月%-d日'],
          augend.date.alias['%Y年%-m月%-d日(%ja)'],
          augend.constant.alias.ja_weekday,
          augend.constant.alias.ja_weekday_full,
        },
      })
      vim.keymap.set({ 'n', 'x' }, '<C-a>', '<Plug>(dial-increment)')
      vim.keymap.set({ 'n', 'x' }, '<C-x>', '<Plug>(dial-decrement)')
      vim.keymap.set({ 'n', 'x' }, 'g<C-a>', 'g<Plug>(dial-increment)')
      vim.keymap.set({ 'n', 'x' }, 'g<C-x>', 'g<Plug>(dial-decrement)')
    end,
  },
  -- Git: gitsigns (mini.diff の代替)
  {
    src = 'lewis6991/gitsigns.nvim',
    config = function()
      local gs = require('gitsigns')
      gs.setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signs_staged_enable = true,
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = { follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,
        update_debounce = 100,
      })
      vim.keymap.set('n', ']c', function()
        gs.nav_hunk('next')
      end, { desc = 'Next hunk' })
      vim.keymap.set('n', '[c', function()
        gs.nav_hunk('prev')
      end, { desc = 'Prev hunk' })
      vim.keymap.set('n', ']C', function()
        gs.nav_hunk('last')
      end, { desc = 'Last hunk' })
      vim.keymap.set('n', '[C', function()
        gs.nav_hunk('first')
      end, { desc = 'First hunk' })
      vim.keymap.set('n', '<Leader>hs', gs.stage_hunk, { desc = 'Stage hunk' })
      vim.keymap.set('n', '<Leader>hr', gs.reset_hunk, { desc = 'Reset hunk' })
      vim.keymap.set('n', '<Leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
    end,
  },
  {
    src = 'esmuellert/codediff.nvim',
    config = function()
      require('codediff').setup({
        explorer = {
          view_mode = 'tree',
        },
        keymaps = {
          view = {
            toggle_explorer = '<localleader>e',
            next_file = '<c-n>',
            prev_file = '<c-p>',
            open_in_prev_tab = '<CR>',
            close_on_open_in_prev_tab = true,
          },
        },
      })

      vim.keymap.set('n', '<Leader>d', '<cmd>CodeDiff<CR>', { desc = 'CodeDiff' })
    end,
  },
}

-- vim.pack.add
vim.pack.add(vim.tbl_map(function(s)
  return { src = 'https://github.com/' .. s.src, version = s.version }
end, plugs))

-- config load
for _, s in ipairs(plugs) do
  if s.config then
    local ok, err = pcall(s.config)
    if not ok then
      vim.notify('[plugins] ' .. s.src .. ': ' .. err, vim.log.levels.WARN)
    end
  end
end

-- commands -----------------------------------------------------------------
vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update all plugins' })

vim.api.nvim_create_user_command('PackClean', function()
  local inactive = vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()

  if #inactive == 0 then
    vim.notify('Nothing to clean', vim.log.levels.INFO)
    return
  end

  vim.notify('Removing: ' .. table.concat(inactive, ', '), vim.log.levels.INFO)
  vim.pack.del(inactive)
end, { desc = 'Remove plugins not in vim.pack.add()' })

vim.api.nvim_create_user_command('PackReinstall', function(opts)
  local names = vim.split(opts.args, '%s+')
  local specs = vim.tbl_map(function(x)
    return x.spec
  end, vim.pack.get(names))

  vim.pack.del(names, { force = true })
  vim.pack.add(specs)

  vim.notify('Reinstalled: ' .. table.concat(names, ', '), vim.log.levels.INFO)
end, {
  nargs = '+',
  desc = 'Reinstall specified plugins',
  complete = function()
    return vim.tbl_map(function(x)
      return x.spec.name
    end, vim.pack.get())
  end,
})

return M
