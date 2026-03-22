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
  end
}
