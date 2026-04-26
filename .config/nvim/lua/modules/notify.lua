local M = {}

local active = {}
local history = {}
local max_history = 50
local display_ms = 3000
local min_width = 30
local max_width_ratio = 0.4

local level_config = {
  [vim.log.levels.ERROR] = {
    icon = ' ',
    hl = 'DiagnosticError',
    title_hl = 'NotifyTitleError',
    name = 'ERROR',
  },
  [vim.log.levels.WARN] = {
    icon = ' ',
    hl = 'DiagnosticWarn',
    title_hl = 'NotifyTitleWarn',
    name = 'WARN',
  },
  [vim.log.levels.INFO] = {
    icon = ' ',
    hl = 'DiagnosticInfo',
    title_hl = 'NotifyTitleInfo',
    name = 'INFO',
  },
  [vim.log.levels.DEBUG] = {
    icon = ' ',
    hl = 'DiagnosticHint',
    title_hl = 'NotifyTitleDebug',
    name = 'DEBUG',
  },
  [vim.log.levels.TRACE] = {
    icon = ' ',
    hl = 'DiagnosticHint',
    title_hl = 'NotifyTitleTrace',
    name = 'TRACE',
  },
}

local function setup_highlights()
  for _, c in pairs(level_config) do
    local fg = vim.api.nvim_get_hl(0, { name = c.hl }).fg
    vim.api.nvim_set_hl(0, c.title_hl, { fg = fg, bold = true })
  end
end

local function calc_width(lines)
  local width = min_width
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 2)
  end
  return math.min(width, math.floor(vim.o.columns * max_width_ratio))
end

local function reposition()
  local bottom = vim.o.lines - vim.o.cmdheight - 1
  for i = #active, 1, -1 do
    local n = active[i]
    if n.win and vim.api.nvim_win_is_valid(n.win) then
      local cfg = vim.api.nvim_win_get_config(n.win)
      local h = cfg.height + 2 -- +2 for border
      bottom = bottom - h
      vim.api.nvim_win_set_config(n.win, {
        relative = 'editor',
        row = bottom,
        col = vim.o.columns - cfg.width - 3, -- -3 for border + margin
      })
    end
  end
end

local function remove_by_id(id)
  for i, n in ipairs(active) do
    if n.id == id then
      if n.timer then
        n.timer:stop()
        n.timer:close()
        n.timer = nil
      end
      if n.win and vim.api.nvim_win_is_valid(n.win) then
        vim.api.nvim_win_close(n.win, true)
      end
      if n.buf and vim.api.nvim_buf_is_valid(n.buf) then
        vim.api.nvim_buf_delete(n.buf, { force = true })
      end
      table.remove(active, i)
      break
    end
  end
  reposition()
end

local function find_active(id)
  for _, n in ipairs(active) do
    if n.id == id then
      return n
    end
  end
  return nil
end

local function add_history(msg, level, title)
  table.insert(history, {
    msg = msg,
    level = level,
    title = title,
    time = os.time(),
  })
  if #history > max_history then
    table.remove(history, 1)
  end
end

local function reset_timer(entry, timeout)
  if entry.timer then
    entry.timer:stop()
    entry.timer:close()
  end
  if timeout == 0 then
    entry.timer = nil
    return
  end
  entry.timer = vim.uv.new_timer()
  entry.timer:start(
    timeout,
    0,
    vim.schedule_wrap(function()
      remove_by_id(entry.id)
    end)
  )
end

local id_counter = 0

local function show(msg, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO
  if type(level) == 'string' then
    level = vim.log.levels[level:upper()] or vim.log.levels.INFO
  end
  local cfg = level_config[level] or level_config[vim.log.levels.INFO]
  local title = opts.title or ''
  local id = opts.id
  local timeout = opts.timeout
  if timeout == nil or timeout == true then
    timeout = display_ms
  end
  if timeout == false then
    timeout = 0
  end

  local lines = vim.split(msg, '\n', { trimempty = true })
  if #lines == 0 then
    lines = { ' ' }
  end
  local width = calc_width(lines)
  local border_title = title ~= '' and { { ' ' .. cfg.icon .. ' ' .. title .. ' ', cfg.title_hl } }
    or nil

  add_history(msg, level, title)

  -- Update existing notification with same id
  local existing = id and find_active(id)
  if existing then
    if
      not (existing.win and vim.api.nvim_win_is_valid(existing.win))
      or not (existing.buf and vim.api.nvim_buf_is_valid(existing.buf))
    then
      remove_by_id(id)
      existing = nil
    end
  end

  if existing then
    vim.bo[existing.buf].modifiable = true
    vim.api.nvim_buf_set_lines(existing.buf, 0, -1, false, lines)
    vim.bo[existing.buf].modifiable = false
    local cur = vim.api.nvim_win_get_config(existing.win)
    vim.api.nvim_win_set_config(existing.win, {
      relative = 'editor',
      row = cur.row,
      col = cur.col,
      width = width,
      height = #lines,
      title = border_title,
      title_pos = border_title and 'center' or nil,
    })
    reset_timer(existing, timeout)
    reposition()
    return existing.id
  end

  -- Create new notification
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- initial position (will be corrected by reposition)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = 0,
    col = 0,
    width = width,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
    title = border_title,
    title_pos = border_title and 'center' or nil,
    focusable = false,
    noautocmd = true,
  })
  vim.api.nvim_set_option_value('winhighlight', 'FloatBorder:' .. cfg.hl, { win = win })

  id_counter = id_counter + 1
  if not id then
    id = id_counter
  end
  local entry = { id = id, win = win, buf = buf, timer = nil }
  table.insert(active, entry)
  reset_timer(entry, timeout)
  reposition()

  return id
end

local function show_history()
  if #history == 0 then
    vim.api.nvim_echo({ { 'No notification history', 'WarningMsg' } }, true, {})
    return
  end

  local lines = {}
  for i = #history, 1, -1 do
    local h = history[i]
    local c = level_config[h.level] or level_config[vim.log.levels.INFO]
    local time = os.date('%H:%M:%S', h.time)
    local title = h.title ~= '' and (' [' .. h.title .. ']') or ''
    table.insert(
      lines,
      string.format('%s %s %s%s: %s', time, c.icon, c.name, title, h.msg:gsub('\n', ' '))
    )
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = { { ' Notification History ', 'Title' } },
    title_pos = 'center',
  })
  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf })
end

function M.setup()
  setup_highlights()

  local group = vim.api.nvim_create_augroup('notify_module', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = setup_highlights,
  })
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = reposition,
  })

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(msg, level, opts)
    if not msg or msg == '' then
      return
    end
    opts = opts or {}
    if opts.id == nil then
      id_counter = id_counter + 1
      opts.id = id_counter
    end
    vim.schedule(function()
      show(msg, level, opts)
    end)
    return opts.id
  end

  vim.api.nvim_create_user_command(
    'NotifyHistory',
    show_history,
    { desc = 'Show notification history' }
  )
end

return M
