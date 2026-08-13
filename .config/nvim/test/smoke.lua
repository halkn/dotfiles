-- Exercises the code paths that only run on real editing events. `nvim --headless
-- '+quitall'` reaches none of them, and emmylua cannot type-check `vim.<module>`
-- fields because they are deferred requires, so a call to a non-existent API
-- (`vim.hl.hl_op`) stays invisible to both until it is triggered by hand.

local failures = {}

-- A sandboxed run cannot spawn processes; that is an environment limit, not a
-- config defect, so it must not fail the run.
local function skippable(msg)
  return msg:match('Process failed to start')
end

-- Errors inside autocmd and keymap callbacks are caught by Neovim and reported
-- through :messages instead of propagating, so pcall alone is not enough.
local function check(name, fn)
  vim.cmd('silent! messages clear')
  local ok, err = pcall(fn)
  if not ok then
    if not skippable(tostring(err)) then
      table.insert(failures, name .. ': ' .. tostring(err))
    end
    return
  end
  vim.wait(50)
  local msgs = vim.api.nvim_exec2('messages', { output = true }).output
  if (msgs:match('E%d+:') or msgs:lower():match('error')) and not skippable(msgs) then
    table.insert(failures, name .. ': ' .. msgs)
  end
end

local function scratch(lines)
  vim.cmd('enew!')
  vim.bo.buftype = 'nofile'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

-- The register provider is irrelevant here and fails without a system clipboard.
vim.o.clipboard = ''

check('yank highlight', function()
  scratch({ 'alpha', 'beta', 'gamma' })
  vim.cmd('normal! yy')
end)

check('yankring paste', function()
  scratch({ 'alpha', 'beta' })
  vim.cmd('normal! yy')
  feed('jp')
end)

-- The cycle undoes the previous paste and redoes it. Deleting the pasted range by
-- byte offsets instead used to split multibyte characters and leave stray bytes.
check('yankring cycle keeps multibyte text intact', function()
  scratch({ 'xyz', 'あい', 'target' })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! $')
  feed('p')
  assert(
    vim.api.nvim_get_current_line() == 'targetあい',
    'paste: ' .. vim.api.nvim_get_current_line()
  )
  feed('<C-n>')
  assert(
    vim.api.nvim_get_current_line() == 'targetxyz',
    'cycle: ' .. vim.api.nvim_get_current_line()
  )
end)

-- A linewise register cannot be expressed as a byte range, so cycling one used to
-- leave the emptied line behind and grow the buffer on every press.
check('yankring cycle handles linewise registers', function()
  scratch({ 'aaa', 'bbb', 'XXX' })
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! yy')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! yy')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  feed('p')
  feed('<C-n>')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(#lines == 4, 'cycle changed the line count: ' .. vim.inspect(lines))
  assert(lines[2] == 'XXX', 'cycle: ' .. vim.inspect(lines))
end)

check('yankring honours an explicit register', function()
  scratch({ 'REG', 'RING', 'target' })
  vim.cmd('normal! "ay$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd('normal! $')
  feed('"ap')
  assert(vim.api.nvim_get_current_line() == 'targetREG', vim.api.nvim_get_current_line())
end)

check('yankring honours a count', function()
  scratch({ 'RING', 'target' })
  vim.cmd('normal! y$')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd('normal! $')
  feed('3p')
  assert(vim.api.nvim_get_current_line() == 'targetRINGRINGRING', vim.api.nvim_get_current_line())
end)

check('surround', function()
  scratch({ 'word' })
  feed('ysiw"')
end)

check('pairs', function()
  scratch({ '' })
  feed('i(foo<Esc>')
end)

-- is_escaped() counts backslashes from the character before the cursor; starting
-- one further back inverted the decision in both directions.
check('pairs respects backslash escapes', function()
  scratch({ 'a\\' })
  feed('A(<Esc>')
  assert(vim.api.nvim_get_current_line() == 'a\\(', vim.api.nvim_get_current_line())
  scratch({ 'a\\\\' })
  feed('A(<Esc>')
  assert(vim.api.nvim_get_current_line() == 'a\\\\()', vim.api.nvim_get_current_line())
end)

check('replace operator', function()
  scratch({ 'alpha beta' })
  vim.cmd('normal! yiw')
  feed('wRiw')
end)

check('comment', function()
  scratch({ 'local x = 1' })
  vim.bo.filetype = 'lua'
  feed(' c')
end)

check('diagnostic float', function()
  scratch({ 'alpha' })
  vim.diagnostic.open_float()
end)

check('notify', function()
  vim.notify('smoke', vim.log.levels.INFO)
  vim.notify('smoke', vim.log.levels.ERROR)
end)

check('statusline', function()
  scratch({ 'alpha' })
  assert(type(require('vimrc.statusline').render()) == 'string')
end)

check('quickfix ftplugin', function()
  vim.fn.setqflist({ { filename = 'init.lua', lnum = 1, text = 'smoke' } })
  vim.cmd('copen')
  vim.cmd('cclose')
end)

check('help ftplugin', function()
  vim.cmd('help help')
  vim.cmd('helpclose')
end)

check('gitcommit ftplugin', function()
  scratch({ 'smoke: message' })
  vim.bo.filetype = 'gitcommit'
end)

check('terminal', function()
  vim.cmd('terminal')
  vim.cmd('stopinsert')
  vim.cmd('bdelete!')
end)

for _, source in ipairs({ 'files', 'buffers', 'grep', 'buf_lines', 'tree', 'git' }) do
  check('picker ' .. source, function()
    local picker = require('vimrc.modules.picker')
    picker.open(source)
    vim.wait(100)
    picker.close()
  end)
end

check('ui.select', function()
  vim.ui.select({ 'a', 'b' }, { prompt = 'smoke' }, function() end)
  vim.wait(100)
  require('vimrc.modules.picker').close()
end)

-- vim.lsp.enable() loads lsp/<name>.lua only once a matching filetype appears,
-- so an error inside one stays hidden until that language is opened. Loading
-- them here surfaces it. The servers are not started; that needs their binaries.
check('lsp configs load', function()
  local files = vim.api.nvim_get_runtime_file('lsp/*.lua', true)
  assert(#files > 0, 'no lsp/*.lua found')
  for _, path in ipairs(files) do
    local config = dofile(path)
    assert(type(config) == 'table', path .. ' did not return a table')
    assert(config.cmd, path .. ' has no cmd')
  end
end)

if #failures > 0 then
  io.stderr:write('smoke test failed:\n' .. table.concat(failures, '\n') .. '\n')
  os.exit(1)
end

io.write('smoke test passed\n')
os.exit(0)
