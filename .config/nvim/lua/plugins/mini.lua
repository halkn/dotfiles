---@type LazySpec
local spec = {

  {
    'nvim-mini/mini.nvim',
    event = { "VeryLazy" },
    config = function()
      require('mini.align').setup()

      require('mini.surround').setup()

      require('mini.splitjoin').setup({ mappings = { toggle = '<Leader>j' } })

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
    end
  },


}

return spec
