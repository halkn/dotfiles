local M = {}

local preview_ns = vim.api.nvim_create_namespace('vimrc_picker_preview')

function M.clear(state)
  if state.preview_buf and vim.api.nvim_buf_is_valid(state.preview_buf) then
    vim.bo[state.preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, {})
    vim.bo[state.preview_buf].modifiable = false
  end
end

function M.show_file(state, path, lnum)
  if not state.preview_buf or not vim.api.nvim_buf_is_valid(state.preview_buf) then
    return
  end

  local ok_binary, raw = pcall(vim.fn.readfile, path, 'b', 1)
  local lines
  if ok_binary and raw[1] and raw[1]:find('\0') then
    lines = { '[バイナリファイル]' }
  else
    local ok, read_lines = pcall(vim.fn.readfile, path, '', 200)
    lines = ok and read_lines or { '[読み込みエラー]' }
  end
  for i, line in ipairs(lines) do
    lines[i] = line:gsub('[\n\r]', '')
  end
  -- An empty file yields no lines, and the lnum highlight below indexes lines[1].
  if #lines == 0 then
    lines = { '' }
  end

  vim.bo[state.preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
  vim.bo[state.preview_buf].modifiable = false

  local filetype = vim.filetype.match({ filename = path })
  if filetype then
    vim.bo[state.preview_buf].filetype = filetype
    pcall(vim.treesitter.start, state.preview_buf, filetype)
  end

  if lnum and state.preview_win and vim.api.nvim_win_is_valid(state.preview_win) then
    local safe_lnum = math.max(1, math.min(lnum, #lines))
    vim.api.nvim_win_set_cursor(state.preview_win, { safe_lnum, 0 })
    vim.api.nvim_buf_clear_namespace(state.preview_buf, preview_ns, 0, -1)
    vim.api.nvim_buf_set_extmark(state.preview_buf, preview_ns, safe_lnum - 1, 0, {
      end_line = safe_lnum - 1,
      end_col = #lines[safe_lnum],
      hl_group = 'CursorLine',
    })
  end
end

function M.update_current(state)
  if not state.use_preview then
    return
  end
  local item = state.filtered[state.cursor_idx]
  local source = state.source_def
  if not item or not source then
    return
  end
  if source.update_preview then
    if
      source.update_preview(item, function(path, lnum)
        M.show_file(state, path, lnum)
      end) == 'clear'
    then
      M.clear(state)
    end
  elseif source.preview_file then
    local path, lnum = source.preview_file(item)
    if path then
      M.show_file(state, path, lnum)
    end
  else
    M.show_file(state, item.text)
  end
end

return M
