local git = require('vimrc.modules.explorer.git')
local explorer = require('vimrc.modules.explorer')
explorer.setup()

local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = assert(vim.uv.fs_realpath(root))

local function command(args)
  local cmd = { 'git', '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false' }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { cwd = root }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

local function fetch(path)
  ---@type table<string, string>?
  local result
  ---@type string?
  local failure
  git.fetch(path, function(status, err)
    result, failure = status, err
  end)
  assert(
    vim.wait(10000, function()
      return result ~= nil
    end),
    'git fetch timed out'
  )
  assert(not failure, failure)
  return assert(result)
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

local function run()
  local parsed = git.parse(
    root,
    table.concat({
      'MM dir/日本 語.txt',
      ' D deleted/a.txt',
      'R  renamed/new.txt',
      'old/ M tricky\nname.txt',
      '?? unknown/line\nbreak.txt',
      '!! ignored.txt',
      'A  added.txt',
      '',
    }, '\0')
  )
  assert(parsed[root .. '/dir/日本 語.txt'] == 'MM')
  assert(parsed[root .. '/dir'] == 'MM')
  assert(parsed[root .. '/deleted'] == ' D')
  assert(parsed[root .. '/renamed/new.txt'] == 'R ')
  assert(parsed[root .. '/old'] == 'R ')
  assert(parsed[root .. '/unknown/line\nbreak.txt'] == ' ?')
  assert(parsed[root .. '/ignored.txt'] == '!!')
  local ignored = git.parse(root, '!! cache/\0!! logs/debug.log\0')
  assert(ignored[root] == nil and ignored[root .. '/logs'] == nil)
  assert(git.status(ignored, root .. '/cache/nested/日本 語.txt') == '!!')
  assert(git.status(ignored, root .. '/cache-other/file.txt') == nil)
  assert(parsed[root .. '/added.txt'] == 'A ')
  assert(parsed[root] == 'RD')
  for _, xy in ipairs({ 'DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU' }) do
    assert(git.parse(root, xy .. ' conflict.txt\0')[root .. '/conflict.txt'] == 'UU')
  end

  assert(next(fetch(root)) == nil, 'non-repository should have no status')
  command({ 'init', '-q' })
  vim.fn.mkdir(root .. '/dir', 'p')
  vim.fn.writefile({ 'base' }, root .. '/dir/file.txt')
  vim.fn.writefile({ 'remove' }, root .. '/dir/deleted.txt')
  vim.fn.writefile({ 'rename' }, root .. '/old.txt')
  command({ 'add', '.' })
  command({
    '-c',
    'user.name=Explorer Test',
    '-c',
    'user.email=test@example.invalid',
    'commit',
    '-qm',
    'fixture',
  })
  assert(next(fetch(root)) == nil, 'clean repository should have no status')
  vim.fn.writefile({ 'staged' }, root .. '/dir/file.txt')
  command({ 'add', 'dir/file.txt' })
  vim.fn.writefile({ 'unstaged' }, root .. '/dir/file.txt')
  vim.fn.delete(root .. '/dir/deleted.txt')
  command({ 'mv', 'old.txt', '日本 語\nnew.txt' })
  vim.fn.writefile({}, root .. '/untracked.txt')
  local statuses = fetch(root .. '/dir')
  assert(statuses[root .. '/dir/file.txt'] == 'MM')
  assert(statuses[root .. '/dir'] == 'MD')
  assert(statuses[root .. '/日本 語\nnew.txt'] == 'R ')
  assert(statuses[root .. '/untracked.txt'] == ' ?')

  explorer.open({ root = root })
  local buf = vim.api.nvim_get_current_buf()
  local ns = vim.api.nvim_get_namespaces().vimrc_explorer_git
  local function marks()
    return vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  end
  assert(vim.wait(10000, function()
    return #marks() > 0
  end))
  local first = assert(marks()[1])
  assert(assert(first[4]).virt_text_pos == 'right_align')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  feed('l')
  local found = false
  for _, mark in ipairs(marks()) do
    local line = assert(vim.api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1])
    if line:find('file.txt', 1, true) then
      local chunks = assert(assert(mark[4]).virt_text)
      assert(assert(chunks[1])[1] == '●' and assert(chunks[3])[1] == '●')
      found = true
    end
  end
  assert(found, 'expanded file should receive both status icons')
  local selected = vim.api.nvim_get_current_line()
  command({ 'add', '.' })
  command({
    '-c',
    'user.name=Explorer Test',
    '-c',
    'user.email=test@example.invalid',
    'commit',
    '-qm',
    'changes',
  })
  feed('u')
  assert(
    vim.wait(10000, function()
      return #marks() == 0
    end),
    'refresh should clear old decorations'
  )
  assert(vim.api.nvim_get_current_line() == selected, 'git refresh moved cursor')
  local target = vim.api.nvim_get_current_win()
  vim.cmd('wincmd p')
  vim.cmd.edit(root .. '/dir/file.txt')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'saved change' })
  vim.cmd.write()
  assert(
    vim.wait(10000, function()
      return #marks() > 0
    end),
    'saving should refresh status'
  )
  assert(vim.api.nvim_get_current_win() ~= target, 'refresh stole focus')
  explorer.close()

  vim.fn.mkdir(root .. '/cache/nested', 'p')
  vim.fn.writefile({}, root .. '/cache/nested/日本 語.txt')
  vim.fn.writefile({}, root .. '/debug.log')
  vim.fn.writefile({}, root .. '/keep.log')
  vim.fn.writefile({}, root .. '/excluded.txt')
  vim.fn.writefile({ 'excluded.txt' }, root .. '/.git/info/exclude')
  vim.fn.writefile({ 'cache/', '*.log', '!keep.log', 'dir/file.txt' }, root .. '/.gitignore')
  local ignored_status = fetch(root)
  assert(ignored_status[root .. '/cache'] == '!!')
  assert(ignored_status[root .. '/debug.log'] == '!!')
  assert(ignored_status[root .. '/excluded.txt'] == '!!')
  assert(ignored_status[root .. '/keep.log'] == ' ?')
  assert(ignored_status[root .. '/dir/file.txt'] == ' M', 'tracked file must retain Git status')
  explorer.open({ root = root .. '/cache' })
  buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(10000, function()
    return #marks() > 0
  end))
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  feed('l')
  local dimmed, marked = false, false
  for _, mark in ipairs(marks()) do
    local line = assert(vim.api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1])
    local details = assert(mark[4])
    if line:find('日本 語.txt', 1, true) then
      if details.hl_group then
        assert(details.hl_group == 'NonText')
        assert(line:sub(mark[3] + 1, details.end_col) == '日本 語.txt')
        dimmed = true
      elseif details.virt_text then
        assert(assert(details.virt_text[2])[1] == '◌')
        marked = true
      end
    end
  end
  assert(dimmed and marked, 'ignored descendants need dimmed names and markers')
  vim.fn.writefile({}, root .. '/.gitignore')
  feed('u')
  assert(
    vim.wait(10000, function()
      for _, mark in ipairs(marks()) do
        if assert(mark[4]).hl_group then
          return false
        end
      end
      return #marks() > 0
    end),
    'refresh must remove ignored name highlights'
  )
  explorer.close()

  local called = false
  local cancel = git.fetch(root, function()
    called = true
  end)
  cancel()
  vim.wait(200)
  assert(not called, 'cancelled fetch delivered stale result')

  local original_system = vim.system
  local pending = {}
  local killed = 0
  vim.system = function(_, _, callback)
    pending[#pending + 1] = callback
    return {
      kill = function()
        killed = killed + 1
      end,
    }
  end
  local ok, err = pcall(function()
    local delivered = false
    local stop = git.fetch(root, function()
      delivered = true
    end)
    pending[1]({ code = 0, stdout = root .. '\n' })
    vim.wait(100, function()
      return #pending == 2
    end)
    stop()
    pending[2]({ code = 0, stdout = ' M stale.txt\0' })
    vim.wait(50)
    assert(killed == 1 and not delivered, 'cancelled status process delivered stale data')
  end)
  vim.system = original_system
  assert(ok, err)
end

local ok, err = xpcall(run, debug.traceback)
explorer.close()
vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('explorer git test passed\n')
vim.cmd('qa!')
