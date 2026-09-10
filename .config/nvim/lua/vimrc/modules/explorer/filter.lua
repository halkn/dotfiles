local M = {}
local input_ns = vim.api.nvim_create_namespace('vimrc_explorer_filter_input')

---@class vimrc.explorer.Filter
---@field query string
---@field root string
---@field hidden boolean
---@field candidates vimrc.explorer.Entry[]?
---@field children table<string, vimrc.explorer.Entry[]>
---@field matches table<string, boolean>
---@field count integer
---@field first string?
---@field loading boolean
---@field error string?
---@field generation integer
---@field input_tick integer
---@field job vim.SystemObj?
---@field input_win integer?
---@field input_buf integer?
---@field on_change fun(search: vimrc.explorer.Filter)
local Filter = {}
Filter.__index = Filter

---@param on_change fun(search: vimrc.explorer.Filter)
---@return vimrc.explorer.Filter
function M.new(on_change)
  return setmetatable({
    query = '',
    root = '',
    hidden = false,
    children = {},
    matches = {},
    count = 0,
    loading = false,
    generation = 0,
    input_tick = 0,
    on_change = on_change,
  }, Filter)
end

function Filter:match()
  self.children, self.matches, self.count, self.first = {}, {}, 0, nil
  if self.query == '' then
    return
  end
  local insensitive = self.query == vim.fn.tolower(self.query)
  local query = insensitive and vim.fn.tolower(self.query) or self.query
  local included = {}
  local function add(entry)
    if included[entry.path] then
      return
    end
    included[entry.path] = true
    local parent = vim.fs.dirname(entry.path)
    self.children[parent] = self.children[parent] or {}
    table.insert(self.children[parent], entry)
  end
  for _, entry in ipairs(self.candidates or {}) do
    local relative = entry.path:sub(#self.root + (self.root == '/' and 1 or 2))
    local text = insensitive and vim.fn.tolower(relative) or relative
    if text:find(query, 1, true) then
      self.matches[entry.path] = true
      self.count = self.count + 1
      self.first = self.first or entry.path
      add(vim.tbl_extend('force', {}, entry))
      local parent = vim.fs.dirname(entry.path)
      while parent and parent ~= self.root do
        add({ path = parent, name = vim.fs.basename(parent), dir = true, link = false, depth = 0 })
        local next_parent = vim.fs.dirname(parent)
        if next_parent == parent then
          break
        end
        parent = next_parent
      end
    end
  end
  for _, children in pairs(self.children) do
    table.sort(children, function(a, b)
      if a.dir ~= b.dir then
        return a.dir
      end
      return a.name < b.name
    end)
  end
end

function Filter:cancel()
  self.generation = self.generation + 1
  if self.job then
    self.job:kill(15)
    self.job = nil
  end
  self.loading = false
end

function Filter:scan()
  self:cancel()
  self.loading, self.error = true, nil
  local generation = self.generation
  local args = {
    'fd',
    '--print0',
    '--no-ignore',
    '--color=never',
    '--type',
    'f',
    '--type',
    'd',
    '--type',
    'l',
  }
  if self.hidden then
    args[#args + 1] = '--hidden'
  end
  local function fail(message)
    self.loading, self.error, self.candidates = false, message, nil
    self:match()
    self.on_change(self)
  end
  local ok, job = pcall(vim.system, args, { cwd = self.root }, function(result)
    vim.schedule(function()
      if self.generation ~= generation then
        return
      end
      self.job = nil
      if result.code ~= 0 then
        fail((result.stderr or ''):match('[^\r\n]+') or 'fd failed')
        return
      end
      local paths = vim.split(result.stdout or '', '\0', { plain = true, trimempty = true })
      local candidates = {}
      local index = 1
      local function collect()
        if self.generation ~= generation then
          return
        end
        -- Yield while resolving entry types so a large tree remains interruptible.
        for _ = 1, 128 do
          local relative = paths[index]
          if not relative then
            self.loading, self.candidates = false, candidates
            table.sort(candidates, function(a, b)
              return a.path < b.path
            end)
            self:match()
            self.on_change(self)
            return
          end
          index = index + 1
          local path = vim.fs.joinpath(self.root, (relative:gsub('^%./', ''):gsub('/$', '')))
          local stat = vim.uv.fs_lstat(path)
          if stat then
            candidates[#candidates + 1] = {
              path = path,
              name = vim.fs.basename(path),
              dir = stat.type == 'directory',
              link = stat.type == 'link',
              depth = 0,
            }
          end
        end
        vim.schedule(collect)
      end
      collect()
    end)
  end)
  if ok then
    self.job = job
  else
    fail(tostring(job))
  end
end

---@param root string
---@param hidden boolean
function Filter:reload(root, hidden)
  self:cancel()
  self.root, self.hidden, self.candidates, self.error = root, hidden, nil, nil
  self:match()
  if self.query ~= '' then
    self:scan()
  end
end

---@param query string
function Filter:set_query(query)
  if self.query == query then
    return
  end
  self.query = query
  if query == '' then
    self:cancel()
    self.error = nil
  elseif not self.candidates and not self.loading then
    self:scan()
  end
  self:match()
  self.on_change(self)
end

function Filter:read_input()
  local buf = self.input_buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    self:set_query(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '')
  end
end

function Filter:close_input()
  self.input_tick = self.input_tick + 1
  local win = self.input_win
  self.input_win, self.input_buf = nil, nil
  if win and vim.api.nvim_win_is_valid(win) then
    if vim.api.nvim_get_current_win() == win then
      vim.cmd.stopinsert()
    end
    vim.api.nvim_win_close(win, true)
  end
end

function Filter:dispose()
  self:close_input()
  self:cancel()
  self.query, self.candidates, self.error = '', nil, nil
  self:match()
end

---@param parent integer
---@param actions { confirm: fun(), move: fun(delta: integer) }
function Filter:open_input(parent, actions)
  if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
    vim.api.nvim_set_current_win(self.input_win)
    vim.cmd.startinsert()
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  self.input_buf = buf
  vim.b[buf].completion = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'vimrc-explorer-filter'
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { self.query })
  vim.api.nvim_buf_set_extmark(buf, input_ns, 0, 0, {
    virt_text = { { '/ ', 'Special' } },
    virt_text_pos = 'inline',
    right_gravity = false,
  })
  self.input_win = vim.api.nvim_open_win(buf, true, {
    relative = 'win',
    win = parent,
    row = 0,
    col = 0,
    width = vim.api.nvim_win_get_width(parent),
    height = 1,
    style = 'minimal',
    border = 'none',
  })
  local function finish()
    self:read_input()
    self:close_input()
    if vim.api.nvim_win_is_valid(parent) then
      vim.api.nvim_set_current_win(parent)
    end
  end
  for _, key in ipairs({ '<Esc>', '<C-c>' }) do
    vim.keymap.set({ 'n', 'i' }, key, finish, { buffer = buf, desc = 'Return to explorer results' })
  end
  vim.keymap.set({ 'n', 'i' }, '<CR>', function()
    self:read_input()
    if self.loading or self.error or (self.query ~= '' and self.count == 0) then
      return
    end
    finish()
    actions.confirm()
  end, { buffer = buf, desc = 'Open selected explorer result' })
  for key, delta in pairs({ ['<C-n>'] = 1, ['<Down>'] = 1, ['<C-p>'] = -1, ['<Up>'] = -1 }) do
    vim.keymap.set(
      { 'n', 'i' },
      key,
      function()
        self:read_input()
        if not self.loading then
          actions.move(delta)
        end
      end,
      { buffer = buf, desc = delta == 1 and 'Next explorer result' or 'Previous explorer result' }
    )
  end
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    buffer = buf,
    callback = function()
      self.input_tick = self.input_tick + 1
      local tick = self.input_tick
      vim.defer_fn(function()
        if self.input_tick == tick then
          self:read_input()
        end
      end, 80)
    end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if self.input_buf == buf then
          self:read_input()
          self:close_input()
        end
      end)
    end,
  })
  vim.api.nvim_win_set_cursor(self.input_win, { 1, #self.query })
  vim.cmd('startinsert!')
end

return M
