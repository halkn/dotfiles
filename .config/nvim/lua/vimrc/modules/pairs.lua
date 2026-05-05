local M = {}

M.config = {
  pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
  },
  quotes = { '"', "'", '`' },
}

local function get_cursor_context()
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  local before = col > 1 and line:sub(col - 1, col - 1) or ''
  local after = line:sub(col, col)
  return before, after
end

local function is_escaped()
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  local bs_count = 0
  for i = col - 2, 1, -1 do
    if line:sub(i, i) == '\\' then
      bs_count = bs_count + 1
    else
      break
    end
  end
  return bs_count % 2 == 1
end

local function close_pair(close)
  if is_escaped() then
    return close
  end
  local _, after = get_cursor_context()
  if after == close then
    return '<Right>'
  end
  return close
end

local function quote_pair(q)
  if is_escaped() then
    return q
  end
  local before, after = get_cursor_context()
  if after == q then
    return '<Right>'
  end
  if before:match('[%w]') and q == "'" then
    return q
  end
  if before == q and q == '`' then
    return q
  end
  return q .. q .. '<Left>'
end

local function backspace()
  local before, after = get_cursor_context()
  for open, close in pairs(M.config.pairs) do
    if before == open and after == close then
      return '<BS><Del>'
    end
  end
  for _, q in ipairs(M.config.quotes) do
    if before == q and after == q then
      return '<BS><Del>'
    end
  end
  return '<BS>'
end

local function cr()
  local before, after = get_cursor_context()
  for open, close in pairs(M.config.pairs) do
    if before == open and after == close then
      return '<CR><C-o>O'
    end
  end
  local line = vim.fn.getline('.')
  if line:match('^%s*```') then
    return '<End><CR>```<C-o>O'
  end
  return '<CR>'
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  local opts = { expr = true, noremap = true }

  for open, close in pairs(M.config.pairs) do
    vim.keymap.set('i', open, function()
      if is_escaped() then
        return open
      end
      return open .. close .. '<Left>'
    end, opts)
    vim.keymap.set('i', close, function()
      return close_pair(close)
    end, opts)
  end

  for _, q in ipairs(M.config.quotes) do
    vim.keymap.set('i', q, function()
      return quote_pair(q)
    end, opts)
  end

  vim.keymap.set('i', '<BS>', backspace, opts)
  vim.keymap.set('i', '<C-h>', backspace, opts)
  vim.keymap.set('i', '<CR>', cr, opts)
end

return M
