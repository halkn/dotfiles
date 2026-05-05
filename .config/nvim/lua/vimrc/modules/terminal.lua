local M = {}

local width_ratio = 0.85
local height_ratio = 0.85

local state = {
  buf = nil,
  win = nil,
}

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

---@return vim.api.keyset.win_config
local function floating_config()
  local width = math.max(1, math.floor(vim.o.columns * width_ratio))
  local height = math.max(1, math.floor(vim.o.lines * height_ratio))
  return {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
  }
end

local function hide()
  if is_valid_window(state.win) then
    vim.api.nvim_win_hide(state.win)
  end
  state.win = nil
end

---@param buf integer|nil
---@return boolean
local function is_terminal_running(buf)
  if not is_valid_buffer(buf) or vim.bo[buf].buftype ~= 'terminal' then
    return false
  end

  local job_id = vim.b[buf].terminal_job_id
  return type(job_id) == 'number' and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

---@return integer
local function ensure_buffer()
  local existing = state.buf
  if existing and is_terminal_running(existing) then
    return existing
  end

  local created = vim.api.nvim_create_buf(false, true)
  state.buf = created
  return created
end

---@param buf integer
local function start_terminal(buf)
  if vim.bo[buf].buftype == 'terminal' then
    return
  end

  vim.api.nvim_buf_call(buf, function()
    vim.cmd.terminal()
  end)
  vim.keymap.set('n', 'q', hide, { buffer = buf })
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = buf })
end

function M.toggle()
  if is_valid_window(state.win) then
    hide()
    return
  end

  local buf = ensure_buffer()
  state.win = vim.api.nvim_open_win(buf, true, floating_config())
  start_terminal(buf)
  vim.cmd.startinsert()
end

function M.setup()
  vim.keymap.set({ 'n', 't' }, '<C-t>', M.toggle, { desc = 'Toggle Terminal' })
end

return M
