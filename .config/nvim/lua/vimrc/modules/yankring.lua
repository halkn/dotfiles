local M = {}

local ring = {}
local ring_idx = 0

M.config = {
  highlight_ms = 200,
  max_size = 30,
}

-- <C-p>/<C-n> replace the text the last paste produced, so its extent has to outlive it.
local last_paste = {
  tick = nil, -- b:changedtick at paste
  start = nil, -- { row, col } 0-indexed
  finish = nil, -- { row, col } 0-indexed
}

local ns = vim.api.nvim_create_namespace('yankring_highlight')
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
  end
  hl_timer = vim.uv.new_timer()
  if not hl_timer then
    return
  end
  hl_timer:start(
    M.config.highlight_ms,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      hl_timer:stop()
      hl_timer:close()
      hl_timer = nil
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

local function paste(after, gp)
  local entry = ring[1]
  if not entry then
    vim.cmd('normal! ' .. (after and 'p' or 'P'))
    return
  end

  ring_idx = 1

  vim.fn.setreg('"', entry.regcontents, entry.regtype)
  local cmd = 'normal! ' .. (after and 'p' or 'P')
  vim.cmd(cmd)

  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  last_paste.tick = vim.b.changedtick
  last_paste.start = { s[1] - 1, s[2] }
  last_paste.finish = { e[1] - 1, e[2] }

  highlight_paste()

  if gp then
    vim.api.nvim_win_set_cursor(0, { e[1], e[2] })
  end
end

local function cycle(delta)
  if last_paste.tick ~= vim.b.changedtick then
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

  local entry = ring[ring_idx]

  local sr, sc = last_paste.start[1], last_paste.start[2]
  local er, ec = last_paste.finish[1], last_paste.finish[2]

  vim.api.nvim_buf_set_text(0, sr, sc, er, ec + 1, {})
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })

  vim.fn.setreg('"', entry.regcontents, entry.regtype)
  vim.cmd('normal! P')

  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  last_paste.tick = vim.b.changedtick
  last_paste.start = { s[1] - 1, s[2] }
  last_paste.finish = { e[1] - 1, e[2] }

  highlight_paste()
end

local function show_ring()
  if #ring == 0 then
    vim.notify('yank ring is empty', vim.log.levels.INFO)
    return
  end
  vim.ui.select(ring, {
    prompt = 'yank ring',
    format_item = function(entry)
      return entry.regcontents:gsub('\n', '\\n')
    end,
  }, function(entry)
    if not entry then
      return
    end
    local lines = vim.split(entry.regcontents, '\n', { plain = true })
    vim.api.nvim_put(lines, entry.regtype, true, true)
  end)
end

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

  local opts = { noremap = true, silent = true }
  vim.keymap.set({ 'n', 'v' }, 'p', function()
    paste(true, false)
  end, opts)
  vim.keymap.set({ 'n', 'v' }, 'P', function()
    paste(false, false)
  end, opts)
  vim.keymap.set({ 'n', 'v' }, 'gp', function()
    paste(true, true)
  end, opts)
  vim.keymap.set({ 'n', 'v' }, 'gP', function()
    paste(false, true)
  end, opts)
  vim.keymap.set('n', '<C-p>', function()
    cycle(-1)
  end, opts)
  vim.keymap.set('n', '<C-n>', function()
    cycle(1)
  end, opts)
  vim.keymap.set('n', '<Leader>y', show_ring, opts)
end

return M
