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
  -- {
  --   src = 'rebelot/kanagawa.nvim',
  --   config = function()
  --     vim.cmd.colorscheme('kanagawa')
  --   end,
  -- },
  {
    src = 'EdenEast/nightfox.nvim',
    config = function()
      require('nightfox').setup({
        options = {
          transparent = true,
        },
      })
      vim.cmd('colorscheme nordfox')
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
  {
    src = 'nvim-mini/mini.nvim',
    config = function()
      -- Git diff
      local md = require('mini.diff')
      md.setup({
        view = {
          style = 'sign',
        },
      })
      vim.keymap.set('n', ']c', function()
        md.goto_hunk('next')
      end, { desc = 'Next hunk' })
      vim.keymap.set('n', '[c', function()
        md.goto_hunk('prev')
      end, { desc = 'Prev hunk' })
      vim.keymap.set('n', ']C', function()
        md.goto_hunk('last')
      end, { desc = 'Last hunk' })
      vim.keymap.set('n', '[C', function()
        md.goto_hunk('first')
      end, { desc = 'First hunk' })
      vim.keymap.set('n', '<Leader>hs', function()
        md.do_hunks(0, 'apply', { scope = 'cursor' })
      end, { desc = 'Stage hunk' })
      vim.keymap.set('n', '<Leader>hr', function()
        md.do_hunks(0, 'reset', { scope = 'cursor' })
      end, { desc = 'Reset hunk' })
      vim.keymap.set('n', '<Leader>hp', md.toggle_overlay, { desc = 'Preview hunk' })
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
