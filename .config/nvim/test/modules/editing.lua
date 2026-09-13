local pairs_module = require('vimrc.modules.pairs')
local replace = require('vimrc.modules.replace')
local surround = require('vimrc.modules.surround')
local yankring = require('vimrc.modules.yankring')

vim.g.mapleader = ' '

pairs_module.setup({
  mappings = {
    pairs = { ['('] = ')', ['['] = ']', ['{'] = '}' },
    quotes = { '"', "'", '`' },
    backspace = { '<BS>', '<C-h>' },
    cr = '<CR>',
  },
})
replace.setup({ mappings = { replace = 'R' } })
surround.setup({ mappings = { add = 'sa', delete = 'sd', replace = 'sr' } })
yankring.setup({
  mappings = {
    paste_after = 'p',
    paste_before = 'P',
    paste_after_end = 'gp',
    paste_before_end = 'gP',
    cycle_prev = '<C-p>',
    cycle_next = '<C-n>',
  },
})

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function scratch(lines)
  vim.cmd('enew!')
  vim.bo.buftype = 'nofile'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function run()
  scratch({ 'word' })
  feed('saiw"')
  assert(vim.api.nvim_get_current_line() == '"word"')

  scratch({ 'alpha beta' })
  vim.cmd('normal! 0v$')
  feed('sa[')
  assert(vim.api.nvim_get_current_line() == '[ alpha beta ]')

  scratch({ 'one two' })
  feed('saiw"')
  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  feed('.')
  assert(vim.api.nvim_get_current_line() == '"one" "two"', vim.api.nvim_get_current_line())

  scratch({ '"alpha"' })
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
  feed('sd"')
  assert(vim.api.nvim_get_current_line() == 'alpha', vim.api.nvim_get_current_line())

  scratch({ '"alpha"' })
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
  feed('sr"[')
  assert(vim.api.nvim_get_current_line() == '[ alpha ]')

  scratch({ 'alpha beta' })
  vim.cmd('normal! yiw')
  feed('wRiw')
  assert(vim.api.nvim_get_current_line() == 'alpha alpha')

  scratch({ 'alpha beta' })
  vim.cmd('normal! 0v$')
  vim.fn.setreg('"', 'replacement')
  feed('R')
  assert(vim.api.nvim_get_current_line() == 'replacement')

  scratch({ 'xyz', 'あい', 'target' })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! $')
  feed('p')
  assert(vim.api.nvim_get_current_line() == 'targetあい')
  feed('<C-n>')
  assert(vim.api.nvim_get_current_line() == 'targetxyz')

  scratch({ 'aaa', 'bbb', 'XXX' })
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! yy')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! yy')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  feed('p<C-n>')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(#lines == 4, 'cycle changed the line count: ' .. vim.inspect(lines))
  assert(lines[2] == 'XXX', 'cycle: ' .. vim.inspect(lines))

  scratch({ 'REG', 'RING', 'target' })
  vim.cmd('normal! "ay$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! $')
  feed('"ap')
  assert(vim.api.nvim_get_current_line() == 'targetREG')

  scratch({ 'RING', 'target' })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! $')
  feed('3p')
  assert(vim.api.nvim_get_current_line() == 'targetRINGRINGRING')

  scratch({ 'a\\' })
  feed('A(<Esc>')
  assert(vim.api.nvim_get_current_line() == 'a\\(')
  scratch({ 'a\\\\' })
  feed('A(<Esc>')
  assert(vim.api.nvim_get_current_line() == 'a\\\\()')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('editing modules test passed\n')
vim.cmd('qa!')
