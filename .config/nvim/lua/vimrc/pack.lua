-- kago.nvim: the modules this configuration owns the wiring for. Deferred
-- until after vim.pack.add() puts kago.nvim on runtimepath.
local configure_kago = function()
  local input = require('kago.input')
  local notify = require('kago.notify')
  local pairs_module = require('kago.pairs')
  local picker = require('kago.picker')
  local explorer = require('kago.explorer')
  local replace = require('kago.replace')
  local surround = require('kago.surround')
  local terminal = require('kago.terminal')
  local yankring = require('kago.yankring')

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.input = input.input
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = picker.ui_select
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = notify.notify

  notify.setup()
  pairs_module.setup({
    mappings = {
      pairs = {
        ['('] = ')',
        ['['] = ']',
        ['{'] = '}',
      },
      quotes = { '"', "'", '`' },
      backspace = { '<BS>', '<C-h>' },
      cr = '<CR>',
    },
  })
  picker.setup()
  explorer.setup()
  replace.setup({ mappings = { replace = 'R' } })
  surround.setup({ mappings = { add = 'sa', delete = 'sd', replace = 'sr' } })
  terminal.setup()
  yankring.setup({
    mappings = {
      paste_after = 'p',
      paste_before = 'P',
      paste_after_end = 'gp',
      paste_before_end = 'gP',
      cycle_prev = '<C-p>',
      cycle_next = '<C-n>',
      show = '<Leader>y',
    },
  })

  -- Personal mappings for module actions stay in the configuration layer.
  vim.keymap.set('n', '<Leader>e', explorer.toggle, { desc = 'explorer: toggle' })
  vim.keymap.set('n', '<Leader>f', picker.files, { desc = 'picker: files' })
  vim.keymap.set('n', '<Leader>b', picker.buffers, { desc = 'picker: buffers' })
  vim.keymap.set('n', '<Leader>G', picker.grep, { desc = 'picker: grep' })
  vim.keymap.set('n', '<Leader>g', picker.git, { desc = 'picker: git' })
  vim.keymap.set('n', '<Leader>l', picker.buf_lines, { desc = 'picker: buf_lines' })
  vim.keymap.set({ 'n', 't' }, '<C-t>', terminal.toggle, { desc = 'Toggle Terminal' })
  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode', remap = true })

  vim.api.nvim_create_user_command('NotifyHistory', notify.show_history, {
    desc = 'Show notification history',
  })
end

-- treesitter -----------------------------------------------------------------
local ts_parsers = { 'go', 'gomod', 'gosum', 'gowork', 'gotmpl' }

local ensure_ts_parsers = function()
  local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(require('nvim-treesitter').get_installed(), lang)
  end, ts_parsers)
  if #missing > 0 then
    require('nvim-treesitter').install(missing)
  end
end

-- hooks --------------------------------------------------------------------
local on_pack_changed = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
    if not ev.data.active then
      vim.cmd.packadd('nvim-treesitter')
    end
    vim.cmd('TSUpdate')
    ensure_ts_parsers()
  end
end

-- plugins ------------------------------------------------------------------
---@class vimrc.pack.Spec
---@field src string
---@field version string?
---@field config fun()?

---@type vimrc.pack.Spec[]
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
      -- Skip in headless runs (e.g. `lint:nvim`) so CI doesn't hit the network.
      if #vim.api.nvim_list_uis() > 0 then
        vim.schedule(ensure_ts_parsers)
      end
    end,
  },
  {
    src = 'saghen/blink.cmp',
    version = 'v1.10.2',
    config = function()
      local opts = {
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
      }
      -- blink.cmp declares every field of its *ConfigPartial types as required,
      -- so the table is built outside the call and cast: the check cannot pass.
      require('blink.cmp').setup(opts --[[@as blink.cmp.Config]])
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
    src = 'halkn/kago.nvim',
    config = configure_kago,
  },
}

local add_plugins = function()
  vim.pack.add(vim.tbl_map(function(spec)
    return { src = 'https://github.com/' .. spec.src, version = spec.version }
  end, plugs))
end

local configure_plugins = function()
  for _, spec in ipairs(plugs) do
    if spec.config then
      local ok, err = pcall(spec.config)
      if not ok then
        vim.notify('[plugins] ' .. spec.src .. ': ' .. err, vim.log.levels.WARN)
      end
    end
  end
end

-- commands -----------------------------------------------------------------
-- Stable Neovim exposes vim.pack only as a Lua API; wrap it in commands until
-- `:packupdate` / `:packdel` land in a stable release.
local update_opts = {
  offline = { offline = true },
  lockfile = { target = 'lockfile' },
}

vim.api.nvim_create_user_command('PackUpdate', function(opts)
  local o = opts.args == '' and {} or update_opts[opts.args]
  if not o then
    vim.notify('PackUpdate: unknown argument: ' .. opts.args, vim.log.levels.ERROR)
    return
  end
  vim.pack.update(nil, o)
end, {
  nargs = '?',
  desc = 'Update all plugins (offline: skip download, lockfile: use lockfile revisions)',
  complete = function()
    return vim.tbl_keys(update_opts)
  end,
})

vim.api.nvim_create_user_command('PackClean', function()
  -- vim.iter is callable through `@operator call`, which the analyzer reads as
  -- taking no arguments.
  local iter = vim.iter --[[@as fun(src: table): Iter]]
  local inactive = iter(vim.pack.get())
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
  local names = opts.fargs
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

vim.api.nvim_create_autocmd('PackChanged', { callback = on_pack_changed })
add_plugins()
configure_plugins()

return { ts_parsers = ts_parsers }
