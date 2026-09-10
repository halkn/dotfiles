local explorer = require('vimrc.modules.explorer')
local preview = require('vimrc.modules.explorer.preview')
explorer.setup()
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/dir', 'p')
root = assert(vim.uv.fs_realpath(root))
vim.fn.writefile({ 'disk content' }, root .. '/a.lua')
vim.fn.writefile({ 'second file' }, root .. '/b.txt')
local fd = assert(vim.uv.fs_open(root .. '/binary', 'w', 384))
assert(vim.uv.fs_write(fd, 'a\0b', 0))
assert(vim.uv.fs_close(fd))
vim.fn.writefile({ string.rep('x', 1024 * 1024 + 1) }, root .. '/large')

local function equal(actual, expected)
  assert(actual == expected, vim.inspect(actual) .. ' ~= ' .. vim.inspect(expected))
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function preview_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'vimrc-explorer-preview' then
      return win
    end
  end
end

local function wait_preview()
  assert(
    vim.wait(1000, function()
      return preview_win() ~= nil
    end),
    'preview did not open'
  )
  return assert(preview_win())
end

local function select(name)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if row > 1 and line:find(name, 1, true) then
      vim.api.nvim_win_set_cursor(0, { row, 0 })
      vim.api.nvim_exec_autocmds('CursorMoved', {})
      return
    end
  end
  error('missing entry: ' .. name)
end

local function run()
  vim.o.columns = 100
  vim.o.hidden = true
  vim.cmd.edit(root .. '/a.lua')
  vim.bo.filetype = 'lua'
  local source, target = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local content = {}
  for i = 1, 250 do
    content[i] = 'local value = ' .. i
  end
  vim.api.nvim_buf_set_lines(source, 0, -1, false, content)
  explorer.open({ root = root })
  local sidebar = vim.api.nvim_get_current_win()
  local target_width = vim.api.nvim_win_get_width(target)
  assert(not preview_win(), 'preview should start disabled')
  select('a.lua')
  feed('P')
  local win = wait_preview()
  local buf = vim.api.nvim_win_get_buf(win)
  equal(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1], content[1])
  equal(vim.bo[buf].syntax == 'lua' or rawget(vim.treesitter.highlighter.active, buf) ~= nil, true)
  assert(not vim.bo[buf].modifiable and not vim.bo[buf].buflisted)
  assert(not vim.api.nvim_win_get_config(win).focusable)
  equal(vim.api.nvim_get_current_win(), sidebar)
  equal(vim.api.nvim_win_get_width(target), target_width)
  feed('<C-d>')
  assert(vim.api.nvim_win_get_cursor(win)[1] > 1)
  equal(vim.api.nvim_win_get_cursor(target)[1], 1)
  feed('<C-u>')
  equal(vim.api.nvim_get_current_win(), sidebar)
  select('b.txt')
  win = wait_preview()
  equal(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1], 'second file')
  assert(not vim.api.nvim_buf_is_valid(buf), 'old scratch buffer leaked')
  select('dir')
  assert(not preview_win(), 'directory should clear preview')
  select('a.lua')
  wait_preview()
  feed('<CR>')
  equal(vim.api.nvim_get_current_win(), target)
  assert(
    vim.wait(1000, function()
      return preview_win() == nil
    end),
    'editing should hide preview'
  )
  assert(vim.bo[source].modified, 'preview lost unsaved changes')
  vim.api.nvim_set_current_win(sidebar)
  wait_preview()
  feed('/')
  local prompt = vim.api.nvim_get_current_win()
  wait_preview()
  feed('<C-n>')
  win = wait_preview()
  equal(vim.api.nvim_get_current_win(), prompt)
  equal(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1], 'second file')
  feed('<Esc>')
  feed('P')
  assert(not preview_win(), 'P should disable preview')
  feed('P')
  wait_preview()
  explorer.close()
  assert(not preview_win(), 'closing explorer leaked preview')

  local p = preview.new()
  p.enabled = true
  local function entry(name)
    return { path = root .. '/' .. name, name = name, dir = false, link = false, depth = 1 }
  end
  vim.cmd('topleft 32vsplit')
  local parent = vim.api.nvim_get_current_win()
  for name, expected in pairs({
    binary = 'Binary file',
    large = '1 MiB',
    missing = 'Cannot read file',
  }) do
    p:update(parent, entry(name))
    win = wait_preview()
    local line = assert(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1])
    assert(line:find(expected, 1, true), line)
  end
  p:update(parent, entry('a.lua'))
  p:update(parent, entry('b.txt'))
  win = wait_preview()
  equal(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1], 'second file')
  p:update(parent, entry('a.lua'))
  p:hide()
  vim.wait(150)
  assert(not preview_win(), 'late callback reopened hidden preview')
  p:update(parent, entry('b.txt'))
  win = wait_preview()
  vim.api.nvim_win_set_width(parent, 85)
  p:update(parent, entry('b.txt'))
  assert(not preview_win(), 'preview should hide when there is not enough space')
  p:hide()
end

local ok, err = xpcall(run, debug.traceback)
explorer.close()
vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('explorer preview test passed\n')
vim.cmd('qa!')
