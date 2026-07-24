local M = {}

local match_ns = vim.api.nvim_create_namespace('vimrc_picker_match')

function M.default_filter(items, query)
  if query == '' then
    return items
  end
  local result = vim.fn.matchfuzzypos(items, query, { key = 'text' })
  local matched, positions = result[1], result[2]
  for i = 1, #matched do
    matched[i]._match_pos = positions[i]
  end
  return matched
end

function M.get_query(state)
  if not state.prompt_buf or not vim.api.nvim_buf_is_valid(state.prompt_buf) then
    return ''
  end
  local line = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, 1, false)[1] or ''
  return line:gsub('^> ', '')
end

function M.render_list(state)
  if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
    return
  end
  local lines = {}
  for _, item in ipairs(state.filtered) do
    table.insert(lines, item.display or item.text)
  end
  vim.bo[state.list_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
  vim.bo[state.list_buf].modifiable = false
  M.apply_match_highlights(state)
end

function M.apply_match_highlights(state)
  if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.list_buf, match_ns, 0, -1)
  local source = state.source_def
  for i, item in ipairs(state.filtered) do
    if item._match_pos then
      local display = item.display or item.text
      local offset = source and source.match_highlight_offset and source.match_highlight_offset()
        or (#display - #item.text)
      for _, pos in ipairs(item._match_pos) do
        local col = offset + pos
        pcall(vim.api.nvim_buf_set_extmark, state.list_buf, match_ns, i - 1, col, {
          end_col = col + 1,
          hl_group = 'PickerMatch',
        })
      end
    end
  end
end

function M.update_cursor(state)
  if not state.list_win or not vim.api.nvim_win_is_valid(state.list_win) then
    return
  end
  local count = #state.filtered
  if count == 0 then
    return
  end
  state.cursor_idx = math.max(1, math.min(state.cursor_idx, count))
  vim.api.nvim_win_set_cursor(state.list_win, { state.cursor_idx, 0 })
end

function M.move_cursor(state, delta, update_preview)
  local count = #state.filtered
  if count == 0 then
    return
  end
  state.cursor_idx = state.cursor_idx + delta
  if state.cursor_idx < 1 then
    state.cursor_idx = count
  elseif state.cursor_idx > count then
    state.cursor_idx = 1
  end
  M.update_cursor(state)
  update_preview()
end

function M.focus_list(state)
  if state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
    vim.api.nvim_set_current_win(state.list_win)
    vim.cmd('stopinsert')
  end
end

function M.focus_prompt(state)
  if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
    vim.api.nvim_set_current_win(state.prompt_win)
    vim.cmd('startinsert!')
  end
end

return M
