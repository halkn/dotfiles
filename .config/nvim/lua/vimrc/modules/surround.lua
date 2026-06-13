-- surround.lua: sa/sd/sr を自作実装（括弧・クォート・任意1文字のみ）
local M = {}

-- opening side はスペースあり、closing side はスペースなし
local surround_map = {
  ['('] = { open = '( ', close = ' )' },
  [')'] = { open = '(', close = ')' },
  ['['] = { open = '[ ', close = ' ]' },
  [']'] = { open = '[', close = ']' },
  ['{'] = { open = '{ ', close = ' }' },
  ['}'] = { open = '{', close = '}' },
}

-- searchpairpos に渡す Vim 正規表現パターン
-- [ ] のみエスケープが必要（() {} はリテラルとして機能する）
local bracket_pairs = {
  ['('] = { open = '(', close = ')', open_pat = '(', close_pat = ')' },
  [')'] = { open = '(', close = ')', open_pat = '(', close_pat = ')' },
  ['['] = { open = '[', close = ']', open_pat = '\\[', close_pat = '\\]' },
  [']'] = { open = '[', close = ']', open_pat = '\\[', close_pat = '\\]' },
  ['{'] = { open = '{', close = '}', open_pat = '{', close_pat = '}' },
  ['}'] = { open = '{', close = '}', open_pat = '{', close_pat = '}' },
}

local function get_surround(char)
  return surround_map[char] or { open = char, close = char }
end

-- カーソルを囲むサラウンドの位置を検出
-- 返り値: { open = {row, col}, close = {row, col} } (0-based row, 0-based col)
local function find_surround(char)
  local pair = bracket_pairs[char]
  if pair then
    -- searchpairpos は行・列ともに 1-based で返す → 0-based に変換
    local op = vim.fn.searchpairpos(pair.open_pat, '', pair.close_pat, 'nbW')
    local cp = vim.fn.searchpairpos(pair.open_pat, '', pair.close_pat, 'nW')
    if op[1] == 0 or cp[1] == 0 then
      return nil
    end
    return { open = { op[1] - 1, op[2] - 1 }, close = { cp[1] - 1, cp[2] - 1 } }
  else
    -- クォート・任意文字: 現在行を左右に探索
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.') - 1
    local left_col, right_col
    for i = col - 1, 0, -1 do
      if line:sub(i + 1, i + 1) == char then
        left_col = i
        break
      end
    end
    for i = col + 1, #line - 1 do
      if line:sub(i + 1, i + 1) == char then
        right_col = i
        break
      end
    end
    if not left_col or not right_col then
      return nil
    end
    return { open = { vim.fn.line('.') - 1, left_col }, close = { vim.fn.line('.') - 1, right_col } }
  end
end

-- 削除範囲を計算: 括弧文字本体 + 直後/直前のスペースをバッファから確認して含める
local function calc_delete_range(pos, char)
  local pair = bracket_pairs[char]
  local open_char = pair and pair.open or char
  local close_char = pair and pair.close or char
  local o_row, o_col = pos.open[1], pos.open[2]
  local c_row, c_col = pos.close[1], pos.close[2]

  local open_line = vim.api.nvim_buf_get_lines(0, o_row, o_row + 1, false)[1]
  local open_end = o_col + #open_char
  if open_line:sub(open_end + 1, open_end + 1) == ' ' then
    open_end = open_end + 1
  end

  local close_line = vim.api.nvim_buf_get_lines(0, c_row, c_row + 1, false)[1]
  local close_start = c_col
  if c_col > 0 and close_line:sub(c_col, c_col) == ' ' then
    close_start = c_col - 1
  end

  return o_row, o_col, open_end, c_row, close_start, c_col + #close_char
end

-- ドット繰り返し用キャッシュ（sa/sd/sr の最後の入力文字を保持）
local cache = {}

M.add_op = function(type)
  local char = cache.add_char or vim.fn.getcharstr()
  cache.add_char = char
  local surr = get_surround(char)
  local s = vim.api.nvim_buf_get_mark(0, '[')
  local e = vim.api.nvim_buf_get_mark(0, ']')
  if type == 'line' then
    local e_line = vim.api.nvim_buf_get_lines(0, e[1] - 1, e[1], false)[1]
    vim.api.nvim_buf_set_text(0, e[1] - 1, #e_line, e[1] - 1, #e_line, { surr.close })
    vim.api.nvim_buf_set_text(0, s[1] - 1, 0, s[1] - 1, 0, { surr.open })
  else
    -- 右端→左端の順で挿入（列位置がずれないよう）
    vim.api.nvim_buf_set_text(0, e[1] - 1, e[2] + 1, e[1] - 1, e[2] + 1, { surr.close })
    vim.api.nvim_buf_set_text(0, s[1] - 1, s[2], s[1] - 1, s[2], { surr.open })
  end
end

M.delete_op = function(_type)
  local char = cache.delete_char or vim.fn.getcharstr()
  cache.delete_char = char
  local pos = find_surround(char)
  if not pos then
    vim.notify('[surround] not found: ' .. char, vim.log.levels.WARN)
    return
  end
  local o_row, o_col, open_end, c_row, close_start, close_end = calc_delete_range(pos, char)
  vim.api.nvim_buf_set_text(0, c_row, close_start, c_row, close_end, {})
  vim.api.nvim_buf_set_text(0, o_row, o_col, o_row, open_end, {})
end

M.replace_op = function(_type)
  local old_char = cache.replace_old or vim.fn.getcharstr()
  local new_char = cache.replace_new or vim.fn.getcharstr()
  cache.replace_old, cache.replace_new = old_char, new_char
  local pos = find_surround(old_char)
  if not pos then
    vim.notify('[surround] not found: ' .. old_char, vim.log.levels.WARN)
    return
  end
  local new_surr = get_surround(new_char)
  local o_row, o_col, open_end, c_row, close_start, close_end = calc_delete_range(pos, old_char)
  vim.api.nvim_buf_set_text(0, c_row, close_start, c_row, close_end, { new_surr.close })
  vim.api.nvim_buf_set_text(0, o_row, o_col, o_row, open_end, { new_surr.open })
end

function M.setup()
  _G._vimrc_surround = M

  -- sa (normal): キャッシュをリセットして g@ + モーション → add_op 内でキャッシュを参照
  vim.keymap.set('n', 'sa', function()
    cache.add_char = nil
    vim.o.operatorfunc = 'v:lua._vimrc_surround.add_op'
    return 'g@'
  end, { expr = true, noremap = true })

  -- sa (visual): '< '> マークから範囲を取得
  vim.keymap.set('x', 'sa', function()
    local char = vim.fn.getcharstr()
    local surr = get_surround(char)
    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'x', false)
    local s = vim.api.nvim_buf_get_mark(0, '<')
    local e = vim.api.nvim_buf_get_mark(0, '>')
    vim.api.nvim_buf_set_text(0, e[1] - 1, e[2] + 1, e[1] - 1, e[2] + 1, { surr.close })
    vim.api.nvim_buf_set_text(0, s[1] - 1, s[2], s[1] - 1, s[2], { surr.open })
  end, { noremap = true })

  -- sd/sr: キャッシュをリセットして g@  → delete_op/replace_op 内でキャッシュを参照
  vim.keymap.set('n', 'sd', function()
    cache.delete_char = nil
    vim.o.operatorfunc = 'v:lua._vimrc_surround.delete_op'
    return 'g@ '
  end, { expr = true, noremap = true })

  vim.keymap.set('n', 'sr', function()
    cache.replace_old, cache.replace_new = nil, nil
    vim.o.operatorfunc = 'v:lua._vimrc_surround.replace_op'
    return 'g@ '
  end, { expr = true, noremap = true })
end

return M
