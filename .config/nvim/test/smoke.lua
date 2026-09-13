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

check('surround', function()
  scratch({ 'word' })
  feed('saiw"')
  assert(vim.api.nvim_get_current_line() == '"word"')
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
end)

check('replace operator', function()
  scratch({ 'alpha beta' })
  vim.cmd('normal! yiw')
  feed('wRiw')
  assert(vim.api.nvim_get_current_line() == 'alpha alpha')
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

check('provider wiring', function()
  local input = require('vimrc.modules.input')
  local notify = require('vimrc.modules.notify')
  local picker = require('vimrc.modules.picker')
  assert(vim.ui.input == input.input)
  assert(vim.ui.select == picker.ui_select)
  assert(vim.notify == notify.notify)
  assert(type(notify.show_history) == 'function')
  assert(vim.api.nvim_get_commands({}).NotifyHistory ~= nil)
end)

check('ui.input', function()
  local confirmed
  vim.ui.input({ prompt = 'smoke', default = 'value' }, function(value)
    confirmed = value
  end)
  vim.wait(10)
  feed('i<CR>')
  assert(confirmed == 'value')

  ---@type string?
  local cancelled = 'pending'
  vim.ui.input({ prompt = 'smoke' }, function(value)
    cancelled = value
  end)
  vim.wait(10)
  feed('i<Esc>')
  assert(cancelled == nil)
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
  -- Deleting the buffer while the pty job is still alive races with the next job
  -- spawn (the picker's fd) and takes the process down. jobwait() also waits for
  -- the on_exit handlers, so nothing is left to tear down afterwards.
  local job_id = vim.b.terminal_job_id
  assert(type(job_id) == 'number', 'no terminal job id')
  vim.fn.jobstop(math.floor(job_id))
  local status = vim.fn.jobwait({ math.floor(job_id) }, 2000)[1]
  assert(status ~= -1, 'terminal job did not exit')
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

check('treesitter parsers declared are installable', function()
  local ts_parsers = require('vimrc.pack').ts_parsers
  local available = require('nvim-treesitter').get_available()
  for _, lang in ipairs(ts_parsers) do
    assert(vim.tbl_contains(available, lang), lang .. ' has no nvim-treesitter parser')
  end
end)

if #failures > 0 then
  io.stderr:write('smoke test failed:\n' .. table.concat(failures, '\n') .. '\n')
  os.exit(1)
end

io.write('smoke test passed\n')
os.exit(0)
