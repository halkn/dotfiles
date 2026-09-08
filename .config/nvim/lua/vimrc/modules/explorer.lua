local M = {}

---@class vimrc.explorer.Entry
---@field path string
---@field name string
---@field dir boolean
---@field link boolean
---@field depth integer

---@class vimrc.explorer.State
---@field root string
---@field expanded table<string, boolean>
---@field entries vimrc.explorer.Entry[]
---@field hidden boolean
---@field selected string
---@field win integer?
---@field buf integer?
---@field target integer?

---@type table<integer, vimrc.explorer.State?>
local states = {}

local function notify(err)
  vim.notify('explorer: ' .. tostring(err), vim.log.levels.WARN)
end

---@param state vimrc.explorer.State
local function visible(state)
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

---@param state vimrc.explorer.State
local function current(state)
  if visible(state) then
    return state.entries[vim.api.nvim_win_get_cursor(assert(state.win))[1]]
  end
end

---@param state vimrc.explorer.State
local function remember(state)
  local entry = current(state)
  if entry then
    state.selected = entry.path
  end
end

---@param state vimrc.explorer.State
local function render(state)
  local buf, win = assert(state.buf), assert(state.win)
  local entries = {
    { path = state.root, name = state.root, dir = true, link = false, depth = 0 },
  }
  local lines = { state.root }
  ---@param path string
  ---@param depth integer
  local function scan(path, depth)
    local handle, err = vim.uv.fs_scandir(path)
    if not handle then
      notify(err)
      return
    end
    local children = {}
    while true do
      local name, kind = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if state.hidden or name:sub(1, 1) ~= '.' then
        local child_path = vim.fs.joinpath(path, name)
        if not kind then
          local stat = vim.uv.fs_lstat(child_path)
          kind = stat and stat.type or 'unknown'
        end
        children[#children + 1] = {
          path = child_path,
          name = name,
          dir = kind == 'directory',
          link = kind == 'link',
          depth = depth,
        }
      end
    end
    table.sort(children, function(a, b)
      if a.dir ~= b.dir then
        return a.dir
      end
      return a.name < b.name
    end)
    for _, entry in ipairs(children) do
      entries[#entries + 1] = entry
      local marker = entry.dir and (state.expanded[entry.path] and '▾ ' or '▸ ') or '  '
      local name = entry.name:gsub('[%c]', function(c)
        return string.format('\\x%02x', c:byte())
      end)
      lines[#lines + 1] = string.rep('  ', depth - 1)
        .. marker
        .. name
        .. (entry.link and ' @' or '')
      if entry.dir and state.expanded[entry.path] then
        scan(entry.path, depth + 1)
      end
    end
  end
  scan(state.root, 1)
  state.entries = entries
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local selected = state.selected
  local row = 1
  while true do
    local found = false
    for i, entry in ipairs(entries) do
      if entry.path == selected then
        row, found = i, true
        break
      end
    end
    local parent = vim.fs.dirname(selected)
    if found or not parent or parent == selected then
      break
    end
    selected = parent
  end
  vim.api.nvim_win_set_cursor(win, { row, 0 })
  remember(state)
end

---@param state vimrc.explorer.State
---@param path string
local function change_root(state, path)
  local stat, err = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'directory' then
    notify(err or ('Not a directory: ' .. path))
    return false
  end
  state.root = path
  return true
end

---@param state vimrc.explorer.State
local function accept(state)
  local entry = current(state)
  if not entry then
    return
  end
  if entry.dir then
    if entry.path ~= state.root then
      state.expanded[entry.path] = not state.expanded[entry.path]
      remember(state)
      render(state)
    end
    return
  end
  local stat, err = vim.uv.fs_stat(entry.path)
  if not stat or stat.type ~= 'file' then
    notify(err or ('Not a regular file: ' .. entry.path))
    return
  end
  local target = state.target
  if
    not target
    or not vim.api.nvim_win_is_valid(target)
    or vim.api.nvim_win_get_tabpage(target) ~= vim.api.nvim_get_current_tabpage()
    or vim.bo[vim.api.nvim_win_get_buf(target)].buftype ~= ''
  then
    vim.cmd('rightbelow vnew')
    target = vim.api.nvim_get_current_win()
  end
  state.target = target
  vim.api.nvim_set_current_win(target)
  local ok, open_err = pcall(vim.cmd.edit, { args = { entry.path } })
  if not ok then
    notify(open_err)
    vim.api.nvim_set_current_win(assert(state.win))
  end
end

---@param state vimrc.explorer.State
local function bind(state)
  local function map(key, callback, desc)
    vim.keymap.set('n', key, callback, { buffer = state.buf, silent = true, desc = desc })
  end
  map('j', 'j', 'Next entry')
  map('k', 'k', 'Previous entry')
  for _, key in ipairs({ '<CR>', 'l' }) do
    map(key, function()
      accept(state)
    end, 'Open file or toggle directory')
  end
  map('h', function()
    local entry = current(state)
    if not entry then
      return
    end
    if entry.dir and state.expanded[entry.path] then
      state.expanded[entry.path] = nil
      state.selected = entry.path
    else
      state.selected = vim.fs.dirname(entry.path) or state.root
    end
    render(state)
  end, 'Collapse directory or select parent')
  map('<BS>', function()
    local old = state.root
    if change_root(state, vim.fs.dirname(old) or old) then
      state.selected = old
      render(state)
    end
  end, 'Go to parent root')
  map('.', function()
    local entry = current(state)
    if entry and entry.dir and change_root(state, entry.path) then
      state.selected = entry.path
      render(state)
    end
  end, 'Set explorer root')
  map('H', function()
    remember(state)
    state.hidden = not state.hidden
    render(state)
  end, 'Toggle hidden files')
  map('u', function()
    remember(state)
    render(state)
  end, 'Refresh explorer')
  map('q', M.close, 'Close explorer')
end

---@param opts? { root?: string }
function M.open(opts)
  local tab = vim.api.nvim_get_current_tabpage()
  local state = states[tab]
  local root = vim.fs.normalize(vim.fn.fnamemodify(opts and opts.root or vim.fn.getcwd(), ':p'))
  if not state then
    state = { root = root, expanded = {}, entries = {}, hidden = false, selected = root }
    if not change_root(state, root) then
      return
    end
    local file = vim.api.nvim_buf_get_name(0)
    local parent = vim.fs.dirname(file)
    local ancestors = {}
    while parent and parent ~= state.root do
      ancestors[#ancestors + 1] = parent
      local next_parent = vim.fs.dirname(parent)
      if next_parent == parent then
        break
      end
      parent = next_parent
    end
    if parent == state.root then
      state.selected = file
      for _, path in ipairs(ancestors) do
        state.expanded[path] = true
      end
    end
    states[tab] = state
  elseif opts and opts.root then
    if not change_root(state, root) then
      return
    end
    state.selected = root
  end
  if visible(state) then
    vim.api.nvim_set_current_win(assert(state.win))
    render(state)
    return
  end
  local target = vim.api.nvim_get_current_win()
  if vim.bo.buftype == '' then
    state.target = target
  end
  local edit_target = state.target
  local buf = vim.api.nvim_create_buf(false, true)
  state.buf = buf
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'vimrc-explorer'
  vim.cmd('topleft 32vsplit')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, buf)
  -- WinEnter sees the copied editing buffer before the split receives its scratch buffer.
  state.target = edit_target
  local wo = vim.wo[state.win]
  wo.number = false
  wo.relativenumber = false
  wo.wrap = false
  wo.cursorline = true
  wo.signcolumn = 'no'
  wo.foldcolumn = '0'
  wo.winfixwidth = true
  wo.spell = false
  wo.list = false
  bind(state)
  render(state)
end

function M.close()
  local state = states[vim.api.nvim_get_current_tabpage()]
  if not state or not visible(state) then
    return
  end
  remember(state)
  if #vim.api.nvim_tabpage_list_wins(0) == 1 then
    vim.cmd('rightbelow vnew')
  end
  vim.api.nvim_win_close(assert(state.win), false)
  state.win, state.buf = nil, nil
end

function M.toggle()
  local state = states[vim.api.nvim_get_current_tabpage()]
  if state and visible(state) then
    M.close()
  else
    M.open()
  end
end

function M.setup()
  vim.keymap.set('n', '<Leader>e', M.toggle, { desc = 'explorer: toggle' })
  local group = vim.api.nvim_create_augroup('vimrc-explorer', { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    callback = function()
      local state = states[vim.api.nvim_get_current_tabpage()]
      if state and state.win == vim.api.nvim_get_current_win() then
        remember(state)
      end
    end,
  })
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      local state = states[vim.api.nvim_get_current_tabpage()]
      if state and vim.bo.buftype == '' then
        state.target = vim.api.nvim_get_current_win()
      end
    end,
  })
  vim.api.nvim_create_autocmd('TabClosed', {
    group = group,
    callback = function()
      for tab in pairs(states) do
        if not vim.api.nvim_tabpage_is_valid(tab) then
          states[tab] = nil
        end
      end
    end,
  })
end

return M
