return {
  src = 'nvim-mini/mini.nvim',
  config = function()
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
  end
}
