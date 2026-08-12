local M = {}

local ring = {}
local ring_idx = 0

---@class vimrc.yankring.Config
---@field highlight_ms integer
---@field max_size integer

---@type vimrc.yankring.Config
M.config = {
  highlight_ms = 200,
  max_size = 30,
}

-- <C-p>/<C-n> undo the last paste and redo it with another entry, so the shape of
-- that paste has to outlive it. Undo is used instead of deleting the pasted range
-- because a byte range cannot express linewise or blockwise registers, and
-- computing its end from `'[`/`']` splits multibyte characters.
---@class vimrc.yankring.LastPaste
---@field tick integer?
---@field cursor [integer, integer]?
---@field seq integer?
---@field after boolean?
---@field gp boolean?
---@field count integer?

---@type vimrc.yankring.LastPaste
local last_paste = {
  tick = nil, -- b:changedtick right after the paste
  cursor = nil, -- { row, col } before the paste, 1-indexed row
  seq = nil, -- undo sequence number before the paste
  after = nil, -- p (true) or P (false)
  gp = nil, -- leave the cursor past the pasted text
  count = nil,
}

local ns = vim.api.nvim_create_namespace('yankring_highlight')
---@type uv.uv_timer_t?
local hl_timer = nil

local function highlight_paste()
  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_extmark(buf, ns, s[1] - 1, s[2], {
    end_row = e[1] - 1,
    end_col = e[2],
    hl_group = 'IncSearch',
  })
  if hl_timer then
    hl_timer:stop()
    hl_timer:close()
    hl_timer = nil
  end
  local timer = vim.uv.new_timer()
  if not timer then
    return
  end
  hl_timer = timer
  -- The callback is scheduled, so a paste can replace hl_timer before it runs.
  -- Touching only this timer keeps it from closing its successor.
  timer:start(
    M.config.highlight_ms,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      if hl_timer == timer then
        hl_timer = nil
      end
    end)
  )
end

local function add(entry)
  if ring[1] and ring[1].regcontents == entry.regcontents and ring[1].regtype == entry.regtype then
    return
  end
  table.insert(ring, 1, entry)
  if #ring > M.config.max_size then
    ring[#ring] = nil
  end
end

local function put(entry, after, gp, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  -- Closes the pending undo block so the paste becomes a state of its own.
  -- Without it a paste issued in the same block as the preceding edit cannot be
  -- rewound separately, and the cycle would undo that edit too.
  vim.cmd('let &undolevels = &undolevels')
  -- Restoring by sequence number rather than plain `:undo` keeps a paste that is
  -- the first change in a buffer from rewinding everything before it.
  local seq = vim.fn.undotree().seq_cur

  vim.fn.setreg('"', entry.regcontents, entry.regtype)
  vim.cmd('normal! ' .. count .. (after and 'p' or 'P'))

  last_paste.tick = vim.b.changedtick
  last_paste.cursor = cursor
  last_paste.seq = seq
  last_paste.after = after
  last_paste.gp = gp
  last_paste.count = count

  highlight_paste()

  if gp then
    local e = vim.api.nvim_buf_get_mark(0, ']')
    vim.api.nvim_win_set_cursor(0, { e[1], e[2] })
  end
end

local function paste(after, gp)
  local register = vim.v.register
  local count = vim.v.count1
  local entry = ring[1]

  -- An explicit register asks for that register, not for the ring.
  if register ~= '"' or not entry then
    vim.cmd('normal! ' .. count .. '"' .. register .. (after and 'p' or 'P'))
    return
  end

  ring_idx = 1
  put(entry, after, gp, count)
end

local function cycle(delta)
  if last_paste.tick ~= vim.b.changedtick then
    return
  end
  -- Bound locally so the nil check narrows the type for nvim_win_set_cursor.
  -- The tick guard above already implies it was set by the last paste.
  local cursor = last_paste.cursor
  if not cursor then
    return
  end
  if #ring == 0 then
    return
  end

  local new_idx = ring_idx + delta
  if new_idx < 1 then
    new_idx = #ring
  end
  if new_idx > #ring then
    new_idx = 1
  end
  ring_idx = new_idx

  vim.cmd('silent! undo ' .. last_paste.seq)
  vim.api.nvim_win_set_cursor(0, cursor)
  put(ring[ring_idx], last_paste.after, last_paste.gp, last_paste.count)
end

local function show_ring()
  if #ring == 0 then
    vim.notify('yank ring is empty', vim.log.levels.INFO)
    return
  end
  vim.ui.select(ring, {
    prompt = 'yank ring',
    format_item = function(entry)
      return (entry.regcontents:gsub('\n', '\\n'))
    end,
  }, function(entry)
    if not entry then
      return
    end
    local lines = vim.split(entry.regcontents, '\n', { plain = true })
    vim.api.nvim_put(lines, entry.regtype, true, true)
  end)
end

---@param opts vimrc.yankring.Config?
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('yankring', { clear = true }),
    callback = function()
      local ev = vim.v.event
      local regcontents = ev.regcontents
      if type(regcontents) == 'table' then
        regcontents = table.concat(regcontents, '\n')
      end
      add({
        regcontents = regcontents,
        regtype = ev.regtype,
      })
    end,
  })

  local map_opts = { noremap = true, silent = true }

  -- x rather than v: in select mode p replaces the selection with a literal "p".
  vim.keymap.set({ 'n', 'x' }, 'p', function()
    paste(true, false)
  end, map_opts)
  vim.keymap.set({ 'n', 'x' }, 'P', function()
    paste(false, false)
  end, map_opts)
  vim.keymap.set({ 'n', 'x' }, 'gp', function()
    paste(true, true)
  end, map_opts)
  vim.keymap.set({ 'n', 'x' }, 'gP', function()
    paste(false, true)
  end, map_opts)
  vim.keymap.set('n', '<C-p>', function()
    cycle(-1)
  end, map_opts)
  vim.keymap.set('n', '<C-n>', function()
    cycle(1)
  end, map_opts)
  vim.keymap.set('n', '<Leader>y', show_ring, map_opts)
end

return M
