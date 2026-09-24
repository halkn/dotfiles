-- Exercises the code paths that only run on real editing events. `nvim --headless
-- '+quitall'` reaches none of them, and emmylua cannot type-check `vim.<module>`
-- fields because they are deferred requires, so a call to a non-existent API
-- (`vim.hl.hl_op`) stays invisible to both until it is triggered by hand.

local failures = {}

-- Errors inside autocmd and keymap callbacks are caught by Neovim and reported
-- through :messages instead of propagating, so pcall alone is not enough.
local function check(name, fn)
  vim.cmd('silent! messages clear')
  local ok, err = pcall(fn)
  if not ok then
    table.insert(failures, name .. ': ' .. tostring(err))
    return
  end
  vim.wait(50)
  local msgs = vim.api.nvim_exec2('messages', { output = true }).output
  if msgs:match('E%d+:') or msgs:lower():match('error') then
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

-- Stop at the root cause instead of reporting secondary failures from a
-- partially configured plugin set.
do
  local config_failures = require('vimrc.pack').config_failures
  if #config_failures > 0 then
    for _, msg in ipairs(config_failures) do
      table.insert(failures, 'plugin config: ' .. msg)
    end
    io.stderr:write('smoke test failed:\n' .. table.concat(failures, '\n') .. '\n')
    os.exit(1)
  end
end

-- configure_plugins() only reaches this on a real plugin failure, and the smoke
-- run's own early exit above means VimEnter itself never fires here either;
-- drive the deferred notify directly with a fake failure to cover it.
check('plugin config failure notify (deferred to VimEnter)', function()
  local captured
  require('vimrc.pack').schedule_failure_notify(function(msg, level)
    captured = { msg = msg, level = level }
  end, { 'smoke-probe: boom' })
  vim.api.nvim_exec_autocmds('VimEnter', {})
  if not captured then
    error('deferred notify did not fire')
  end
  assert(captured.msg:match('smoke%-probe: boom'), 'wrong message: ' .. tostring(captured.msg))
  assert(captured.level == vim.log.levels.ERROR, 'wrong level: ' .. tostring(captured.level))
end)

check('yank highlight', function()
  scratch({ 'alpha', 'beta', 'gamma' })
  vim.cmd('normal! yy')
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
-- here.
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

-- This is a dotfiles integration boundary: kago.replace owns the R operator,
-- while the personal RR mapping must still enter builtin Replace mode.
check('RR enters Replace mode', function()
  scratch({ 'abcdef' })
  feed('RRxyz<Esc>')
  assert(vim.api.nvim_get_current_line() == 'xyzdef')
end)

check('statusline', function()
  scratch({ 'alpha' })
  assert(type(require('vimrc.statusline').render()) == 'string')
end)

check('quickfix autocmd and ftplugin', function()
  vim.fn.setqflist({ { filename = 'init.lua', lnum = 1, text = 'smoke' } })
  vim.api.nvim_exec_autocmds('QuickFixCmdPost', { pattern = 'vimgrep' })
  assert(vim.bo.buftype == 'quickfix', 'quickfix window did not open')
  local map = vim.fn.maparg('q', 'n', false, true)
  assert(map.buffer == 1, 'missing buffer-local q mapping')
  vim.cmd('cclose')
end)

check('help ftplugin', function()
  vim.cmd('help help')
  for _, lhs in ipairs({ '<CR>', '<BS>', 'q' }) do
    local map = vim.fn.maparg(lhs, 'n', false, true)
    assert(map.buffer == 1, 'missing buffer-local mapping: ' .. lhs)
  end
  vim.cmd('helpclose')
end)

check('gitcommit ftplugin', function()
  scratch({ 'smoke: message' })
  vim.bo.filetype = 'gitcommit'
  assert(vim.wo.spell, 'spell is disabled')
  assert(vim.bo.spelllang == 'cjk,en', 'wrong spelllang: ' .. vim.bo.spelllang)
end)

check('terminal autocmd', function()
  scratch({ '' })
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.signcolumn = 'yes'
  vim.api.nvim_exec_autocmds('TermOpen', { buffer = 0 })
  vim.cmd('stopinsert')
  assert(not vim.wo.number, 'number is enabled')
  assert(not vim.wo.relativenumber, 'relativenumber is enabled')
  local signcolumn = vim.api.nvim_get_option_value('signcolumn', { scope = 'local', win = 0 })
  assert(signcolumn == 'no', 'wrong signcolumn: ' .. signcolumn)
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
    local name = vim.fn.fnamemodify(path, ':t:r')
    assert(vim.lsp.is_enabled(name), name .. ' is not in servers')
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
