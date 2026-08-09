local M = {}

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
    if type(win) == 'number' and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    state[key] = nil
  end
  for _, key in ipairs({ 'prompt_buf', 'list_buf', 'preview_buf' }) do
    local buf = state[key]
    if type(buf) == 'number' and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    state[key] = nil
  end

  M.reset_session(state)
end

return M
