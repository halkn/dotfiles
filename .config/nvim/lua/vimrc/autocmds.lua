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

-- terminal: nvim's own TermOpen autocmd already turns off number and signcolumn.
autocmd('TermOpen', {
  group = group_name,
  callback = function()
    vim.cmd.startinsert()
  end,
})

-- Briefly highlight yanked text
autocmd('TextYankPost', {
  group = group_name,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})
