local autocmd = vim.api.nvim_create_autocmd

local group_name = 'vimrc_config'
vim.api.nvim_create_augroup(group_name, { clear = true })

-- Quickfix
autocmd('QuickFixCmdPost', {
  group = group_name,
  pattern = { 'make', 'grep', 'grepadd', 'vimgrep', 'vimgrepadd' },
  callback = function()
    vim.cmd.cwin()
  end,
})

-- help
autocmd('FileType', {
  group = group_name,
  pattern = { 'help' },
  callback = function()
    vim.cmd('wincmd L')
  end,
})

-- terminal
autocmd('TermOpen', {
  group = group_name,
  callback = function()
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = 'no'
    vim.cmd.startinsert()
  end,
})

-- Briefly highlight yanked text
autocmd('TextYankPost', {
  group = group_name,
  callback = function()
    vim.hl.hl_op({ timeout = 200 })
  end,
})
