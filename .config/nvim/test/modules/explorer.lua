local explorer = require('vimrc.modules.explorer')
explorer.setup()

local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/dir/empty', 'p')
root = assert(vim.uv.fs_realpath(root))
vim.fn.writefile({ 'hello' }, root .. '/dir/日本 語.txt')
vim.fn.writefile({ 'hidden' }, root .. '/.hidden')
vim.fn.writefile({ 'file' }, root .. '/z.txt')
assert(vim.uv.fs_symlink(root, root .. '/cycle'))

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function find(name)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find(name, 1, true) then
      return row
    end
  end
end

local function select(name)
  local row = assert(find(name), 'missing entry: ' .. name)
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end

local function run()
  vim.o.columns = 120
  vim.o.hidden = true
  vim.cmd.enew()
  local target = vim.api.nvim_get_current_win()
  local modified = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(modified, 0, -1, false, { 'unsaved' })
  local cwd = vim.fn.getcwd()
  explorer.open({ root = root })
  local sidebar = vim.api.nvim_get_current_win()
  assert(vim.wo.winfixwidth and vim.api.nvim_win_get_width(0) == 32)
  assert(not vim.bo.modifiable and vim.bo.buftype == 'nofile')
  assert(find('dir') == 2, 'directories must sort first')
  assert(not find('.hidden'))
  select('dir')
  feed('l')
  assert(find('empty') and find('日本 語.txt'))
  select('empty')
  feed('l')
  assert(vim.api.nvim_get_current_line():find('▾', 1, true))
  feed('h')
  assert(vim.api.nvim_get_current_line():find('▸', 1, true))
  feed('h')
  assert(vim.api.nvim_get_current_line():find('dir', 1, true))
  select('日本 語.txt')
  explorer.close()
  explorer.open()
  sidebar = vim.api.nvim_get_current_win()
  assert(vim.api.nvim_get_current_line():find('日本 語.txt', 1, true))
  feed('<CR>')
  assert(vim.api.nvim_get_current_win() == target)
  assert(
    vim.api.nvim_buf_get_name(0) == root .. '/dir/日本 語.txt',
    vim.api.nvim_buf_get_name(0)
  )
  assert(vim.api.nvim_win_is_valid(sidebar))
  assert(vim.bo[modified].modified)
  assert(vim.api.nvim_buf_get_lines(modified, 0, -1, false)[1] == 'unsaved')
  vim.api.nvim_set_current_win(sidebar)
  feed('H')
  assert(find('.hidden'))
  vim.fn.writefile({}, root .. '/new.txt')
  feed('u')
  assert(find('new.txt') and find('日本 語.txt'))
  assert(vim.api.nvim_get_current_line():find('日本 語.txt', 1, true))
  select('new.txt')
  assert(vim.fn.delete(root .. '/new.txt') == 0)
  feed('u')
  assert(not find('new.txt'))
  assert(vim.api.nvim_win_get_cursor(0)[1] == 1)
  select('dir')
  feed('.')
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == root .. '/dir')
  assert(vim.fn.getcwd() == cwd)
  feed('<BS>')
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == root)
  assert(vim.api.nvim_get_current_line():find('dir', 1, true))
  select('cycle')
  local count = vim.api.nvim_buf_line_count(0)
  local notify = vim.notify
  local notices = {}
  vim.notify = function(message)
    notices[#notices + 1] = message
  end
  feed('l')
  vim.notify = notify
  assert(#notices == 1, 'directory symlink should notify without opening')
  assert(vim.api.nvim_buf_line_count(0) == count)

  vim.cmd.tabnew()
  explorer.open({ root = root .. '/dir' })
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == root .. '/dir')
  explorer.close()
  vim.cmd.tabclose()
  assert(vim.api.nvim_get_current_win() == sidebar)
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == root)

  vim.api.nvim_win_close(target, false)
  select('z.txt')
  feed('l')
  assert(vim.api.nvim_buf_get_name(0) == root .. '/z.txt')
  assert(vim.api.nvim_get_current_win() ~= sidebar)
  assert(vim.api.nvim_win_get_width(sidebar) == 32, 'recreated target changed sidebar width')
  vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
  explorer.close()
  assert(#vim.api.nvim_tabpage_list_wins(0) == 1)
  assert(vim.api.nvim_get_option_value('buftype', { buf = 0 }) == '')
  for _, reopen in ipairs({ explorer.open, explorer.toggle }) do
    explorer.open()
    local replaced_win, old_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    vim.cmd.enew()
    local replacement = vim.api.nvim_get_current_buf()
    assert(not vim.api.nvim_buf_is_valid(old_buf))
    reopen()
    assert(vim.api.nvim_win_is_valid(replaced_win), 'replacement window was closed')
    assert(vim.api.nvim_win_get_buf(replaced_win) == replacement)
    assert(vim.bo.filetype == 'vimrc-explorer')
    explorer.close()
  end
  explorer.open()
  explorer.toggle()
  assert(vim.api.nvim_get_option_value('buftype', { buf = 0 }) == '')
end

local ok, err = xpcall(run, debug.traceback)
explorer.close()
vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('explorer test passed\n')
vim.cmd('qa!')
