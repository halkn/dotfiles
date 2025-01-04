local autocmd = vim.api.nvim_create_autocmd

local group_name = "vimrc_config"
vim.api.nvim_create_augroup(group_name, { clear = true })

-- Quickfix
autocmd('QuickfixCmdPost', {
  group = group_name,
  pattern = { "make", "grep", "grepadd", "vimgrep", "vimgrepadd" },
  callback = function()
    vim.cmd.cwin()
  end,
})

autocmd('FileType', {
  group = group_name,
  pattern = { "qf" },
  callback = function()
    local opts = { silent = false, noremap = true, buffer = true }
    vim.keymap.set('n', 'q', '<cmd>cclose<cr>', opts)
  end,
})

-- help
autocmd('FileType', {
  group = group_name,
  pattern = { "help" },
  callback = function()
    local opts = { silent = false, noremap = true, buffer = true }
    vim.keymap.set('n', '<CR>', '<C-]>', opts)
    vim.keymap.set('n', '<BS>', '<C-T>', opts)
    vim.cmd('wincmd L')
  end
})
autocmd('BufEnter', {
  group = group_name,
  pattern = { "*.txt" },
  command = [[if &buftype == 'help' | wincmd L | endif]],
})

-- terminal
autocmd('TermOpen', {
  group = group_name,
  callback = function()
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
    vim.cmd.startinsert()
  end,
})

-- git
autocmd('FileType', {
  group = group_name,
  pattern = { "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "cjk,en"
  end,
})

-- Briefly highlight yanked text
autocmd('TextYankPost', {
  group = group_name,
  callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})
