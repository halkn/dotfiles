return {
  src = 'nvim-mini/mini.nvim',
  config = function()
    -- Text editing
    require('mini.align').setup()
    require('mini.operators').setup({
      replace = { prefix = 'R' },
      exchange = { prefix = 'g/' },
    })
    vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
    require('mini.splitjoin').setup({ mappings = { toggle = '<Leader>j' } })
    require('mini.surround').setup()

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

    -- Git commands
    local mg = require('mini.git')
    mg.setup()
    vim.keymap.set('n', '<Leader>hb', mg.show_at_cursor, { desc = 'Blame line' })
    require('mini.input').setup({})
  end,
}
