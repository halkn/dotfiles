local M = {}

-- Every field starts nil and is filled in by M.open(), so without this class the
-- analyzer infers the whole session state as nil and reports every guard against
-- it as dead code.
---@class vimrc.picker.State
---@field prompt_buf integer?
---@field prompt_win integer?
---@field list_buf integer?
---@field list_win integer?
---@field preview_buf integer?
---@field preview_win integer?
---@field source_name string?
---@field source_def table?
---@field all_items table[]
---@field filtered table[]
---@field cursor_idx integer
---@field use_preview boolean
---@field async_job table?
---@field debounce_timer uv.uv_timer_t?
---@field origin_win integer?
---@field origin_buf integer?
---@field on_select fun(item: table)?
---@field augroup integer?
---@field source_opts table
---@field on_esc fun()?
---@field on_cursor_moved fun(idx: integer)?
---@field generation integer

---@return vimrc.picker.State
function M.new()
  return {
    prompt_buf = nil,
    prompt_win = nil,
    list_buf = nil,
    list_win = nil,
    preview_buf = nil,
    preview_win = nil,
    source_name = nil,
    source_def = nil,
    all_items = {},
    filtered = {},
    cursor_idx = 1,
    use_preview = false,
    async_job = nil,
    debounce_timer = nil,
    origin_win = nil,
    origin_buf = nil,
    on_select = nil,
    augroup = nil,
    source_opts = {},
    on_esc = nil,
    on_cursor_moved = nil,
    generation = 0,
  }
end

function M.begin(state)
  state.generation = state.generation + 1
  return state.generation
end

function M.cancel_timer(state)
  local timer = state.debounce_timer
  if timer then
    timer:stop()
    timer:close()
    state.debounce_timer = nil
  end
end

function M.set_timer(state, timer)
  M.cancel_timer(state)
  state.debounce_timer = timer
end

function M.cancel_job(state)
  local job = state.async_job
  if job then
    pcall(function()
      job:kill(9)
    end)
    state.async_job = nil
  end
end

function M.set_job(state, job)
  if state.async_job ~= job then
    M.cancel_job(state)
  end
  state.async_job = job
end

function M.clear_augroup(state)
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end
end

function M.reset_session(state)
  state.source_name = nil
  state.source_def = nil
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.use_preview = false
  state.origin_win = nil
  state.origin_buf = nil
  state.on_select = nil
  state.source_opts = {}
  state.on_esc = nil
  state.on_cursor_moved = nil
end

function M.cleanup(state, on_close)
  M.clear_augroup(state)
  M.cancel_timer(state)
  M.cancel_job(state)

  if on_close then
    on_close(state.source_def)
  end

  for _, key in ipairs({ 'prompt_win', 'list_win', 'preview_win' }) do
    local win = state[key]
    if type(win) == 'number' then
      local handle = math.floor(win)
      if vim.api.nvim_win_is_valid(handle) then
        vim.api.nvim_win_close(handle, true)
      end
    end
    state[key] = nil
  end
  for _, key in ipairs({ 'prompt_buf', 'list_buf', 'preview_buf' }) do
    local buf = state[key]
    if type(buf) == 'number' then
      local handle = math.floor(buf)
      if vim.api.nvim_buf_is_valid(handle) then
        vim.api.nvim_buf_delete(handle, { force = true })
      end
    end
    state[key] = nil
  end

  M.reset_session(state)
end

return M
