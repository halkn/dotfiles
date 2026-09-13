local original_notify = vim.notify
local original_select = vim.ui.select

local input = require('vimrc.modules.input')
local notify = require('vimrc.modules.notify')
local picker = require('vimrc.modules.picker')
local explorer = require('vimrc.modules.explorer')
local replace = require('vimrc.modules.replace')
local surround = require('vimrc.modules.surround')
local terminal = require('vimrc.modules.terminal')
local yankring = require('vimrc.modules.yankring')
local pairs_module = require('vimrc.modules.pairs')

assert(rawequal(vim.ui.select, original_select))
assert(rawequal(vim.notify, original_notify))

assert(type(input.input) == 'function')
assert(type(notify.notify) == 'function')
notify.setup()
pairs_module.setup()
picker.setup()
explorer.setup()
replace.setup()
surround.setup()
terminal.setup()
yankring.setup()

assert(rawequal(vim.ui.select, original_select))
assert(rawequal(vim.notify, original_notify))
for _, lhs in ipairs({ 'sa', 'sd', 'sr', 'R', 'p', 'P', 'gp', 'gP', '<C-p>', '<C-n>' }) do
  assert(vim.fn.maparg(lhs, 'n') == '', 'unexpected normal mapping: ' .. lhs)
end
assert(vim.fn.maparg('<Leader>f', 'n') == '')
assert(vim.fn.maparg('<Leader>e', 'n') == '')
assert(vim.fn.maparg('<C-t>', 'n') == '')

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function scratch(lines)
  vim.cmd('enew!')
  vim.bo.buftype = 'nofile'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

surround.setup({ mappings = { add = 'za' } })
scratch({ 'word' })
feed('zaiw"')
assert(vim.api.nvim_get_current_line() == '"word"')

replace.setup({ mappings = { replace = 'Q' } })
scratch({ 'word' })
vim.fn.setreg('"', 'replacement')
feed('Qiw')
assert(vim.api.nvim_get_current_line() == 'replacement')

pairs_module.setup({ mappings = { quotes = { '~' } } })
scratch({ '' })
feed('i~<Esc>')
assert(vim.api.nvim_get_current_line() == '~~')

yankring.setup({ mappings = { paste_after = 'zP' } })
scratch({ 'source', 'target' })
vim.cmd('normal! y$')
vim.api.nvim_win_set_cursor(0, { 2, 5 })
feed('zP')
assert(vim.api.nvim_get_current_line() == 'targetsource')

vim.cmd('qa!')
