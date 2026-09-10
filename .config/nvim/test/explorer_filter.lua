local filter = require('vimrc.modules.explorer.filter')
local explorer = require('vimrc.modules.explorer')
explorer.setup()

local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/closed/deep', 'p')
vim.fn.mkdir(root .. '/.hidden', 'p')
root = assert(vim.uv.fs_realpath(root))
for _, name in ipairs({
  'closed/deep/Target.lua',
  'target.lua',
  '[literal].txt',
  '日本 語.txt',
  'ignored.txt',
  '.hidden/target.txt',
}) do
  vim.fn.writefile({ name }, root .. '/' .. name)
end
vim.fn.writefile({ 'ignored.txt' }, root .. '/.ignore')
assert(vim.uv.fs_symlink(root, root .. '/cycle'))

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function row_for(buf, name)
  for row, line in ipairs(lines(buf)) do
    if row > 1 and line:find(name, 1, true) then
      return row
    end
  end
end

local function equal(actual, expected, message)
  assert(actual == expected, message or (vim.inspect(actual) .. ' ~= ' .. vim.inspect(expected)))
end

local function run()
  local search = filter.new(function() end)
  search:reload(root, false)
  search:set_query('target')
  assert(
    vim.wait(5000, function()
      return not search.loading
    end),
    'candidate scan timed out'
  )
  assert(not search.error, search.error)
  equal(search.count, 2)
  assert(#search.children[root] > 0 and #search.children[root .. '/closed'] > 0)
  local candidates = search.candidates
  search:set_query('Target')
  equal(search.count, 1)
  assert(search.matches[root .. '/closed/deep/Target.lua'])
  assert(search.candidates == candidates, 'query edit should reuse candidate cache')
  search:set_query('[literal]')
  equal(search.count, 1, 'query should be literal, not a pattern')
  search:set_query('日本 語')
  equal(search.count, 1)
  search:set_query('ignored')
  equal(search.count, 1, 'search should include ignored files like the normal tree')
  search:set_query('cycle/')
  equal(search.count, 0, 'search must not follow directory symlinks')
  search:set_query('target')
  search:reload(root, true)
  assert(vim.wait(5000, function()
    return not search.loading
  end))
  equal(search.count, 3)
  search:dispose()

  explorer.open({ root = root })
  local sidebar, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local original_lines = lines(buf)
  local original_cursor = vim.api.nvim_win_get_cursor(sidebar)
  assert(not row_for(buf, 'Target.lua'))
  feed('/')
  local input = vim.api.nvim_get_current_buf()
  local input_win = vim.api.nvim_get_current_win()
  assert(vim.bo[input].filetype == 'vimrc-explorer-filter')
  vim.api.nvim_buf_set_lines(input, 0, -1, false, { 'target' })
  vim.api.nvim_exec_autocmds('TextChangedI', { buffer = input })
  assert(
    vim.wait(5000, function()
      return row_for(buf, 'Target.lua') ~= nil
    end),
    'live input should show results from collapsed directories'
  )
  assert(vim.api.nvim_get_current_win() == input_win, 'render stole focus from input')
  assert(row_for(buf, 'closed') and row_for(buf, 'deep'))
  assert(not row_for(buf, 'ignored.txt'))
  local selected_row = vim.api.nvim_win_get_cursor(sidebar)[1]
  feed('<C-n>')
  equal(vim.api.nvim_win_get_cursor(sidebar)[1], selected_row + 1)
  equal(vim.api.nvim_get_current_win(), input_win)
  feed('<C-p>')
  equal(vim.api.nvim_win_get_cursor(sidebar)[1], selected_row)
  feed('<Down><Up>')
  equal(vim.api.nvim_win_get_cursor(sidebar)[1], selected_row)
  equal(vim.api.nvim_get_current_win(), input_win)
  feed('<CR>')
  equal(vim.api.nvim_buf_get_name(0), root .. '/closed/deep/Target.lua')
  assert(not vim.api.nvim_buf_is_valid(input), 'confirm should wipe the input buffer')
  vim.api.nvim_set_current_win(sidebar)
  feed('/')
  input = vim.api.nvim_get_current_buf()
  feed('<Esc>')
  assert(vim.api.nvim_get_current_win() == sidebar)
  assert(not vim.api.nvim_buf_is_valid(input), 'input scratch buffer should be wiped')
  assert(assert(lines(buf)[1]):find('2 matches', 1, true))
  feed('<Esc>')
  assert(vim.deep_equal(lines(buf), original_lines), 'clear should restore expansion state')
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(sidebar), original_cursor))

  feed('/no-such-path<Esc>')
  assert(
    vim.wait(5000, function()
      return assert(lines(buf)[1]):find('0 matches', 1, true) ~= nil
    end),
    'zero results should be explicit'
  )
  assert(#lines(buf) == 1)
  feed('/<CR>')
  equal(vim.bo.filetype, 'vimrc-explorer-filter')
  feed('<Esc>')
  feed('<Esc>')
  feed('/Target<Esc>')
  assert(vim.wait(5000, function()
    return row_for(buf, 'Target.lua') ~= nil
  end))
  vim.api.nvim_win_set_cursor(sidebar, { assert(row_for(buf, 'deep')), 0 })
  feed('/<CR>')
  assert(lines(buf)[1] == root, 'opening a search directory should leave filtering')
  assert(row_for(buf, 'Target.lua'), 'selected directory should remain expanded')
  assert(vim.api.nvim_get_current_line():find('deep', 1, true))

  feed('/target<Esc>')
  assert(vim.wait(5000, function()
    return assert(lines(buf)[1]):find('2 matches', 1, true) ~= nil
  end))
  feed('H')
  assert(vim.wait(5000, function()
    return assert(lines(buf)[1]):find('3 matches', 1, true) ~= nil
  end))
  vim.fn.writefile({}, root .. '/new-target.txt')
  feed('u')
  assert(vim.wait(5000, function()
    return row_for(buf, 'new-target.txt') ~= nil
  end))
  vim.api.nvim_win_set_cursor(sidebar, { assert(row_for(buf, 'Target.lua')), 0 })
  feed('<CR>')
  assert(vim.api.nvim_buf_get_name(0) == root .. '/closed/deep/Target.lua')
  explorer.close()
  explorer.open({ root = root })
  sidebar, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  feed('/')
  local prompt = vim.api.nvim_get_current_buf()
  explorer.close()
  assert(not vim.api.nvim_buf_is_valid(prompt), 'closing explorer should clean up its prompt')
  explorer.open({ root = root })
  assert(not vim.api.nvim_get_current_line():find('matches', 1, true))
  explorer.close()

  local system = vim.system
  local pending = {}
  vim.system = function(_, _, callback)
    pending[#pending + 1] = callback
    return { kill = function() end }
  end
  local ok, err = pcall(function()
    local f = filter.new(function() end)
    f:reload(root, false)
    f:set_query('target')
    f:reload(root .. '/closed', false)
    pending[1]({ code = 0, stdout = 'target.lua\0' })
    pending[2]({ code = 0, stdout = 'deep/Target.lua\0' })
    assert(vim.wait(1000, function()
      return not f.loading
    end))
    assert(f.count == 1 and f.matches[root .. '/closed/deep/Target.lua'])
    f:reload(root, false)
    f:dispose()
    pending[3]({ code = 0, stdout = 'target.lua\0' })
    vim.wait(50)
    assert(f.candidates == nil and f.query == '', 'closed filter accepted a stale scan')
  end)
  vim.system = system
  assert(ok, err)
end

local ok, err = xpcall(run, debug.traceback)
explorer.close()
vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('explorer filter test passed\n')
vim.cmd('qa!')
