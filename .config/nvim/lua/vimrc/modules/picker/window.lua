local M = {}

local _saved_guicursor = nil

function M.calc_layout(config)
  local total_w = vim.o.columns
  local total_h = vim.o.lines
  local w = math.floor(total_w * config.width_ratio)
  local h = math.floor(total_h * config.height_ratio)
  local row = math.floor((total_h - h) / 2)
  local col = math.floor((total_w - w) / 2)
  return { w = w, h = h, row = row, col = col }
end

function M.create_windows(layout, title, use_preview, footer)
  local prompt_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt_buf].buftype = 'prompt'
  vim.bo[prompt_buf].filetype = 'picker_prompt'

  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = 'editor',
    row = layout.row,
    col = layout.col,
    width = layout.w,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. (title or 'picker') .. ' ',
    title_pos = 'center',
  })

  -- prompt: 内容1行 + border2行 = 3行
  -- list/preview: border付きなので内容高さ = layout.h - 3 - 2
  local content_h = layout.h - 5

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[list_buf].buftype = 'nofile'
  vim.bo[list_buf].filetype = 'picker_list'

  local list_w, preview_buf, preview_win
  if use_preview then
    list_w = math.floor((layout.w - 3) * 0.45)
    local preview_w = layout.w - list_w - 3
    preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_buf].buftype = 'nofile'

    preview_win = vim.api.nvim_open_win(preview_buf, false, {
      relative = 'editor',
      row = layout.row + 3,
      col = layout.col + list_w + 2,
      width = preview_w,
      height = content_h,
      style = 'minimal',
      border = 'rounded',
    })
    vim.wo[preview_win].wrap = false
    vim.wo[preview_win].cursorline = false
  else
    list_w = layout.w
  end

  local list_win = vim.api.nvim_open_win(list_buf, false, {
    relative = 'editor',
    row = layout.row + 3,
    col = layout.col,
    width = list_w,
    height = content_h,
    style = 'minimal',
    border = 'rounded',
    footer = footer and (' ' .. footer .. ' ') or nil,
    footer_pos = footer and 'right' or nil,
  })
  vim.wo[list_win].wrap = false
  vim.wo[list_win].cursorline = true
  vim.wo[list_win].cursorcolumn = false
  vim.wo[list_win].number = false
  vim.wo[list_win].relativenumber = false
  vim.wo[list_win].statusline = ' '
  vim.wo[list_win].winhighlight = 'CursorLine:PmenuSel,CursorLineBg:PmenuSel'

  return prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win
end

function M.hide_cursor()
  if not _saved_guicursor then
    _saved_guicursor = vim.o.guicursor
  end
  vim.api.nvim_set_hl(0, 'PickerHiddenCursor', { blend = 100, nocombine = true })
  vim.o.guicursor = 'a:PickerHiddenCursor/PickerHiddenCursor'
end

function M.restore_cursor()
  if _saved_guicursor then
    vim.o.guicursor = _saved_guicursor
    _saved_guicursor = nil
  end
end

return M
