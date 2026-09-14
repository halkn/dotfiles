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

-- Representative integration check that a dotfiles-configured mapping ('sa')
-- reaches kago.surround; the operator's own regressions live in kago.nvim.
check('surround', function()
  scratch({ 'word' })
  feed('saiw"')
  assert(vim.api.nvim_get_current_line() == '"word"')
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
  local input = require('kago.input')
  local notify = require('kago.notify')
  local picker = require('kago.picker')
  assert(vim.ui.input == input.input)
  assert(vim.ui.select == picker.ui_select)
  assert(vim.notify == notify.notify)
  assert(type(notify.show_history) == 'function')
  assert(vim.api.nvim_get_commands({}).NotifyHistory ~= nil)
end)

-- Mapping values are dotfiles configuration; kago.nvim owns none of them, so
-- their presence has no equivalent regression on the kago.nvim side. Wiring to
-- the wrong kago function (e.g. <Leader>g and <Leader>G swapped) reports
-- 'wired' without checking the callback, so compare identity where dotfiles
-- passes a named function directly. Surround/pairs/replace/yankring bind
-- anonymous closures inside kago itself and can only be checked for presence
-- here; the 'surround' check above covers one of them behaviorally.
check('personal mappings wired', function()
  local explorer = require('kago.explorer')
  local picker = require('kago.picker')
  local terminal = require('kago.terminal')
  local yankring = require('kago.yankring')

  local wired = {
    { lhs = '<Leader>e', fn = explorer.toggle },
    { lhs = '<Leader>f', fn = picker.files },
    { lhs = '<Leader>b', fn = picker.buffers },
    { lhs = '<Leader>G', fn = picker.grep },
    { lhs = '<Leader>g', fn = picker.git },
    { lhs = '<Leader>l', fn = picker.buf_lines },
    { lhs = '<C-t>', fn = terminal.toggle },
    { lhs = '<Leader>y', fn = yankring.show },
  }
  for _, m in ipairs(wired) do
    local map = vim.fn.maparg(m.lhs, 'n', false, true)
    assert(map.callback == m.fn, 'wrong callback for ' .. m.lhs)
  end

  for _, lhs in ipairs({ 'sa', 'sd', 'sr', 'R', 'RR' }) do
    assert(vim.fn.maparg(lhs, 'n') ~= '', 'missing mapping: ' .. lhs)
  end
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

-- Representative integration check that the picker opens through the provider;
-- per-source behavior regressions live in kago.nvim.
check('picker files', function()
  local picker = require('kago.picker')
  picker.open('files')
  vim.wait(100)
  picker.close()
end)

check('ui.select', function()
  vim.ui.select({ 'a', 'b' }, { prompt = 'smoke' }, function() end)
  vim.wait(100)
  require('kago.picker').close()
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
