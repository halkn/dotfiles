return {
  src = 'lewis6991/gitsigns.nvim',
  config = function()
    require('gitsigns').setup({
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigation
        map('n', ']c', function()
          gs.nav_hunk('next')
        end, 'Next hunk')
        map('n', '[c', function()
          gs.nav_hunk('prev')
        end, 'Prev hunk')
        map('n', ']C', function()
          gs.nav_hunk('last')
        end, 'Last hunk')
        map('n', '[C', function()
          gs.nav_hunk('first')
        end, 'First hunk')

        -- Actions
        map('n', '<Leader>hs', gs.stage_hunk, 'Stage hunk')
        map('n', '<Leader>hr', gs.reset_hunk, 'Reset hunk')
        map('n', '<Leader>hp', gs.preview_hunk, 'Preview hunk')
        map('n', '<Leader>hb', function()
          gs.blame_line({ full = true })
        end, 'Blame line')
      end,
    })
  end,
}
