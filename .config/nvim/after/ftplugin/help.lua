local opts = { buffer = true, noremap = true, silent = false }

vim.keymap.set('n', '<CR>', '<C-]>', opts)
vim.keymap.set('n', '<BS>', '<C-T>', opts)
vim.keymap.set('n', 'q', '<cmd>q<cr>', opts)

-- Last, so a context that forbids moving windows cannot stop the mappings above.
vim.cmd('wincmd L')
