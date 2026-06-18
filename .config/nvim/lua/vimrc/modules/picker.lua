-- picker.lua: 自前 fuzzy finder
-- telescope/snacks 風の floating window UI
local M = {}
local original_ui_select = vim.ui.select
local preview_ns = vim.api.nvim_create_namespace('vimrc_picker_preview')
local match_ns = vim.api.nvim_create_namespace('vimrc_picker_match')

M.config = {
  debounce_ms = 150,
  height_ratio = 0.8,
  width_ratio = 0.9,
  exclude_globs = {
    '!**/.git/*',
    '!*.png',
    '!*.jpg',
    '!*.jpeg',
    '!*.gif',
    '!*.bmp',
    '!*.svg',
    '!*.ico',
    '!*.webp',
    '!*.tiff',
    '!*.psd',
    '!*.icns',
    '!*.pdf',
    '!*.doc',
    '!*.docx',
    '!*.xls',
    '!*.xlsx',
    '!*.zip',
    '!*.tar',
    '!*.gz',
    '!*.bz2',
    '!*.xz',
    '!*.7z',
    '!*.mp3',
    '!*.mp4',
    '!*.avi',
    '!*.mkv',
    '!*.mov',
    '!*.flac',
    '!*.bin',
    '!*.exe',
    '!*.dll',
    '!*.so',
    '!*.dylib',
    '!*.o',
  },
}

-- SECTION 1: State -------------------------------------------------------
local state = {
  prompt_buf = nil,
  prompt_win = nil,
  list_buf = nil,
  list_win = nil,
  preview_buf = nil,
  preview_win = nil,
  source_name = nil,
  all_items = {},
  filtered = {},
  cursor_idx = 1,
  use_preview = false,
  async_job = nil,
  debounce_timer = nil,
  origin_win = nil,
  origin_buf = nil,
  on_select = nil,
  _augroup = nil,
  no_ignore = false,
  tree_root = nil,
  tree_open_dirs = {},
  tree_all_files = nil,
  tree_nav_mode = false,
  _saved_guicursor = nil,
}

-- SECTION 2: Utilities ---------------------------------------------------
local function debounce(fn, ms)
  return function(...)
    local args = { ... }
    if state.debounce_timer then
      state.debounce_timer:stop()
    end
    state.debounce_timer = vim.uv.new_timer()
    state.debounce_timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        if state.debounce_timer then
          state.debounce_timer:stop()
          state.debounce_timer:close()
          state.debounce_timer = nil
        end
        fn(unpack(args))
      end)
    )
  end
end

local function calc_layout()
  local total_w = vim.o.columns
  local total_h = vim.o.lines
  local w = math.floor(total_w * M.config.width_ratio)
  local h = math.floor(total_h * M.config.height_ratio)
  local row = math.floor((total_h - h) / 2)
  local col = math.floor((total_w - w) / 2)
  return { w = w, h = h, row = row, col = col }
end

-- SECTION 3: Sources -----------------------------------------------------

-- アイコン取得（mini.icons → nvim-web-devicons → nil の順に試みる）
-- 必ずメインスレッド（vim.schedule内）から呼ぶこと
local _icon_fn = nil
local function get_icon(filepath, is_dir)
  if _icon_fn == false then
    return nil
  end
  if _icon_fn == nil then
    local ok, icons = pcall(require, 'mini.icons')
    if ok and icons.get then
      if not icons.config then
        pcall(icons.setup, {})
      end
      _icon_fn = function(p, dir)
        local cat = dir and 'directory' or 'file'
        local ok2, icon = pcall(icons.get, cat, p)
        if ok2 and icon and icon ~= '' then
          return icon
        end
        return nil
      end
    else
      local ok2, devicons = pcall(require, 'nvim-web-devicons')
      if ok2 then
        _icon_fn = function(p, dir)
          if dir then
            return '\xef\x81\xbb'
          end
          local ext = vim.fn.fnamemodify(p, ':e')
          return devicons.get_icon(p, ext)
        end
      else
        _icon_fn = false
        return nil
      end
    end
  end
  return _icon_fn(filepath, is_dir)
end

-- SECTION 2.5: Tree helpers -----------------------------------------------
local function tree_ensure_children(node)
  if node.children ~= nil then
    return
  end
  node.children = {}
  local cwd = vim.uv.cwd()
  local abs = node.path == '.' and cwd or (cwd .. '/' .. node.path)
  local handle = vim.uv.fs_scandir(abs)
  if not handle then
    return
  end
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    local rel = node.path == '.' and name or (node.path .. '/' .. name)
    local is_dir = typ == 'directory'
    if typ == 'link' then
      local st = vim.uv.fs_stat(abs .. '/' .. name)
      is_dir = st and st.type == 'directory' or false
    end
    table.insert(node.children, {
      name = name,
      path = rel,
      is_dir = is_dir,
      children = nil,
    })
  end
  table.sort(node.children, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.name < b.name
  end)
end

local function tree_flatten()
  local items = {}
  local function walk(node, depth)
    tree_ensure_children(node)
    if not node.children then
      return
    end
    for _, child in ipairs(node.children) do
      local indent = string.rep('  ', depth)
      local display
      if child.is_dir then
        local expanded = state.tree_open_dirs[child.path]
        local dir_icon = expanded and '\xef\x81\xbc' or '\xef\x81\xbb'
        display = indent .. dir_icon .. ' ' .. child.name
      else
        local icon = get_icon(child.name) or ''
        display = indent .. (icon ~= '' and (icon .. ' ') or '  ') .. child.name
      end
      table.insert(items, {
        text = child.path,
        display = display,
        _tree_node = child,
      })
      if child.is_dir and state.tree_open_dirs[child.path] then
        walk(child, depth + 1)
      end
    end
  end
  if state.tree_root then
    walk(state.tree_root, 0)
  end
  return items
end

local function tree_build_filtered(matched_items)
  local root = { children = {} }
  local node_map = { [''] = root }

  for _, item in ipairs(matched_items) do
    local parts = vim.split(item.text, '/')
    local parent = root
    local current_path = ''
    for i = 1, #parts do
      current_path = i == 1 and parts[i] or (current_path .. '/' .. parts[i])
      if not node_map[current_path] then
        local node = {
          name = parts[i],
          path = current_path,
          is_dir = (i < #parts),
          children = {},
        }
        node_map[current_path] = node
        table.insert(parent.children, node)
      end
      parent = node_map[current_path]
    end
  end

  local function sort_tree(node)
    if node.children then
      table.sort(node.children, function(a, b)
        if a.is_dir ~= b.is_dir then
          return a.is_dir
        end
        return a.name < b.name
      end)
      for _, child in ipairs(node.children) do
        sort_tree(child)
      end
    end
  end
  sort_tree(root)

  local items = {}
  local function walk(node, depth)
    for _, child in ipairs(node.children or {}) do
      local indent = string.rep('  ', depth)
      local display
      if child.is_dir then
        display = indent .. '\xef\x81\xbc ' .. child.name
      else
        local icon = get_icon(child.name) or ''
        display = indent .. (icon ~= '' and (icon .. ' ') or '  ') .. child.name
      end
      table.insert(items, {
        text = child.path,
        display = display,
        _tree_node = child,
      })
      if child.is_dir then
        walk(child, depth + 1)
      end
    end
  end
  walk(root, 0)
  return items
end

local function tree_load_all_files()
  local cmd = { 'rg', '--files', '--hidden' }
  for _, glob in ipairs(M.config.exclude_globs) do
    vim.list_extend(cmd, { '--glob', glob })
  end
  local job = vim.system(cmd, { text = true }, function(result)
    local items = {}
    if result.code == 0 and result.stdout then
      for line in result.stdout:gmatch('[^\n]+') do
        table.insert(items, { text = line })
      end
    end
    vim.schedule(function()
      if state.source_name == 'tree' then
        state.tree_all_files = items
      end
    end)
  end)
  state.async_job = job
end

local sources = {}

sources.files = {
  name = 'files',
  use_preview = true,
  load = function(callback)
    local items = {}
    local cmd = { 'rg', '--files', '--hidden' }
    for _, glob in ipairs(M.config.exclude_globs) do
      vim.list_extend(cmd, { '--glob', glob })
    end
    if state.no_ignore then
      table.insert(cmd, '--no-ignore')
    end
    local job = vim.system(cmd, { text = true }, function(result)
      -- パス収集のみ行い、アイコン取得はメインスレッドで実行する
      local raw = {}
      if result.code == 0 and result.stdout then
        for line in result.stdout:gmatch('[^\n]+') do
          table.insert(raw, line)
        end
      end
      vim.schedule(function()
        for _, line in ipairs(raw) do
          local icon = get_icon(line)
          local display = icon and (icon .. ' ' .. line) or line
          table.insert(items, { text = line, display = display })
        end
        callback(items)
      end)
    end)
    return job
  end,
  filter = function(items, query)
    if query == '' then
      return items
    end
    local r = vim.fn.matchfuzzypos(items, query, { key = 'text' })
    local matched, positions = r[1], r[2]
    for i = 1, #matched do
      matched[i]._match_pos = positions[i]
    end
    return matched
  end,
}

sources.buffers = {
  name = 'buffers',
  use_preview = false,
  load = function(callback)
    local items = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= '' then
          local icon = get_icon(name)
          local display = icon and (icon .. ' ' .. name) or name
          table.insert(items, { text = name, display = display, buf = buf })
        end
      end
    end
    vim.schedule(function()
      callback(items)
    end)
    return nil
  end,
  filter = function(items, query)
    if query == '' then
      return items
    end
    local r = vim.fn.matchfuzzypos(items, query, { key = 'text' })
    local matched, positions = r[1], r[2]
    for i = 1, #matched do
      matched[i]._match_pos = positions[i]
    end
    return matched
  end,
}

sources.grep = {
  name = 'grep',
  use_preview = true,
  load = function(callback)
    -- 初期表示は空
    vim.schedule(function()
      callback({})
    end)
    return nil
  end,
  filter = function(_items, _query)
    -- grep はクエリ変更時に再実行するため、filter は使わない
    return _items
  end,
  on_query_change = nil, -- 後で設定
}

sources.buf_lines = {
  name = 'buf_lines',
  use_preview = false,
  load = function(callback)
    local lines = vim.api.nvim_buf_get_lines(state.origin_buf, 0, -1, false)
    local items = {}
    for i, line in ipairs(lines) do
      table.insert(items, { text = line, lnum = i })
    end
    vim.schedule(function()
      callback(items)
    end)
    return nil
  end,
  filter = function(items, query)
    if query == '' then
      return items
    end
    local r = vim.fn.matchfuzzypos(items, query, { key = 'text' })
    local matched, positions = r[1], r[2]
    for i = 1, #matched do
      matched[i]._match_pos = positions[i]
    end
    return matched
  end,
}

sources.tree = {
  name = 'tree',
  use_preview = true,
}

-- SECTION 4: Window management -------------------------------------------
local function _create_windows(layout, title, use_preview, footer)
  -- prompt window（1行）
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

  -- list / preview の高さ
  -- prompt: 内容1行 + border2行 = 3行
  -- list/preview: border付きなので内容高さ = layout.h - 3 - 2
  local content_h = layout.h - 5

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[list_buf].buftype = 'nofile'
  vim.bo[list_buf].filetype = 'picker_list'

  local list_w, preview_buf, preview_win
  if use_preview then
    -- list内容幅 / preview内容幅（両方にborderがつくので -3 を分配）
    list_w = math.floor((layout.w - 3) * 0.45)
    local preview_w = layout.w - list_w - 3
    preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_buf].buftype = 'nofile'

    -- list右border(1) + 隙間なし で preview左borderを並べる
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

local function hide_cursor()
  if not state._saved_guicursor then
    state._saved_guicursor = vim.o.guicursor
  end
  vim.api.nvim_set_hl(0, 'PickerHiddenCursor', { blend = 100, nocombine = true })
  vim.o.guicursor = 'a:PickerHiddenCursor/PickerHiddenCursor'
end

local function restore_cursor()
  if state._saved_guicursor then
    vim.o.guicursor = state._saved_guicursor
    state._saved_guicursor = nil
  end
end

function M.close()
  -- autocmd グループを削除
  if state._augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state._augroup)
    state._augroup = nil
  end

  -- debounce timer を停止
  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer:close()
    state.debounce_timer = nil
  end

  -- 非同期ジョブを停止
  if state.async_job then
    pcall(function()
      state.async_job:kill(9)
    end)
    state.async_job = nil
  end

  -- ウィンドウ・バッファを閉じる
  for _, win_key in ipairs({ 'prompt_win', 'list_win', 'preview_win' }) do
    local win = state[win_key]
    if type(win) == 'number' and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    state[win_key] = nil
  end
  for _, buf_key in ipairs({ 'prompt_buf', 'list_buf', 'preview_buf' }) do
    local buf = state[buf_key]
    if type(buf) == 'number' and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    state[buf_key] = nil
  end

  -- 元ウィンドウにフォーカスを戻す
  local origin = state.origin_win
  state.origin_win = nil
  state.origin_buf = nil
  state.on_select = nil
  state.source_name = nil
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.use_preview = false
  state.no_ignore = false
  restore_cursor()
  state.tree_root = nil
  state.tree_open_dirs = {}
  state.tree_all_files = nil
  state.tree_nav_mode = false

  if origin and vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
end

-- SECTION 5: List rendering ----------------------------------------------
local function _apply_match_highlights()
  if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.list_buf, match_ns, 0, -1)
  for i, item in ipairs(state.filtered) do
    if item._match_pos then
      local display = item.display or item.text
      -- display = icon + " " + text のとき offset = #icon + 1
      local offset = #display - #item.text
      for _, pos in ipairs(item._match_pos) do
        local col = offset + pos
        pcall(vim.api.nvim_buf_set_extmark, state.list_buf, match_ns, i - 1, col, {
          end_col = col + 1,
          hl_group = 'Search',
        })
      end
    end
  end
end

local function _render_list()
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
  _apply_match_highlights()
end

local function _update_cursor()
  if not state.list_win or not vim.api.nvim_win_is_valid(state.list_win) then
    return
  end
  local count = #state.filtered
  if count == 0 then
    return
  end
  local idx = math.max(1, math.min(state.cursor_idx, count))
  state.cursor_idx = idx
  vim.api.nvim_win_set_cursor(state.list_win, { idx, 0 })
end

local function _move_cursor(delta)
  local count = #state.filtered
  if count == 0 then
    return
  end
  state.cursor_idx = state.cursor_idx + delta
  if state.cursor_idx < 1 then
    state.cursor_idx = count
  end
  if state.cursor_idx > count then
    state.cursor_idx = 1
  end
  _update_cursor()
  if state.use_preview then
    local item = state.filtered[state.cursor_idx]
    if item then
      M._update_preview(item)
    end
  end
end

-- SECTION 6: Preview -----------------------------------------------------
function M._preview_file(path, lnum)
  if not state.preview_buf or not vim.api.nvim_buf_is_valid(state.preview_buf) then
    return
  end

  -- バイナリ判定: 先頭8KBにNULバイトがあればバイナリとみなす
  local ok_b, raw = pcall(vim.fn.readfile, path, 'b', 1)
  if ok_b and raw[1] and raw[1]:find('\0') then
    vim.bo[state.preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, { '[バイナリファイル]' })
    vim.bo[state.preview_buf].modifiable = false
    return
  end

  local ok, lines = pcall(vim.fn.readfile, path, '', 200)
  if not ok then
    vim.bo[state.preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, { '[読み込みエラー]' })
    vim.bo[state.preview_buf].modifiable = false
    return
  end

  -- 念のため行内の改行文字を除去（readfileが稀に返すケース）
  for i, line in ipairs(lines) do
    lines[i] = line:gsub('[\n\r]', '')
  end

  vim.bo[state.preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
  vim.bo[state.preview_buf].modifiable = false

  -- filetype 検出してシンタックスハイライト
  local ft = vim.filetype.match({ filename = path })
  if ft then
    vim.bo[state.preview_buf].filetype = ft
    pcall(vim.treesitter.start, state.preview_buf, ft)
  end

  -- 該当行にスクロール & ハイライト
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

function M._update_preview(item)
  if not state.use_preview then
    return
  end
  if not item then
    return
  end

  local src = state.source_name
  if src == 'tree' then
    if item._tree_node and item._tree_node.is_dir then
      if state.preview_buf and vim.api.nvim_buf_is_valid(state.preview_buf) then
        vim.bo[state.preview_buf].modifiable = true
        vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, {})
        vim.bo[state.preview_buf].modifiable = false
      end
      return
    end
    M._preview_file(item.text, nil)
  elseif src == 'files' then
    M._preview_file(item.text, nil)
  elseif src == 'grep' then
    -- grep: "file:lnum:col:text" 形式
    local path, lnum = item.text:match('^([^:]+):(%d+):')
    if path then
      M._preview_file(path, tonumber(lnum))
    end
  end
end

-- SECTION 6.5: Tree UI ---------------------------------------------------
local function tree_expand()
  local item = state.filtered[state.cursor_idx]
  if not item or not item._tree_node then
    return
  end
  local node = item._tree_node
  if node.is_dir then
    state.tree_open_dirs[node.path] = true
    tree_ensure_children(node)
    state.filtered = tree_flatten()
    state.all_items = state.filtered
    _render_list()
    _update_cursor()
    if state.use_preview and state.filtered[state.cursor_idx] then
      M._update_preview(state.filtered[state.cursor_idx])
    end
  else
    M._accept()
  end
end

local function tree_collapse()
  local item = state.filtered[state.cursor_idx]
  if not item or not item._tree_node then
    return
  end
  local node = item._tree_node
  if node.is_dir and state.tree_open_dirs[node.path] then
    state.tree_open_dirs[node.path] = nil
    state.filtered = tree_flatten()
    state.all_items = state.filtered
    state.cursor_idx = math.min(state.cursor_idx, math.max(1, #state.filtered))
    _render_list()
    _update_cursor()
    if state.use_preview and state.filtered[state.cursor_idx] then
      M._update_preview(state.filtered[state.cursor_idx])
    end
  else
    local parent_path = vim.fn.fnamemodify(node.path, ':h')
    if parent_path == '.' or parent_path == '' then
      return
    end
    for i, it in ipairs(state.filtered) do
      if it.text == parent_path then
        state.cursor_idx = i
        _update_cursor()
        if state.use_preview then
          M._update_preview(state.filtered[i])
        end
        break
      end
    end
  end
end

local function tree_enter_nav_mode()
  if state.source_name ~= 'tree' then
    return
  end
  state.tree_nav_mode = true
  if state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
    vim.api.nvim_set_current_win(state.list_win)
    vim.cmd('stopinsert')
  end
  hide_cursor()
end

local function tree_enter_search_mode()
  if state.source_name ~= 'tree' then
    return
  end
  state.tree_nav_mode = false
  restore_cursor()
  if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
    vim.api.nvim_set_current_win(state.prompt_win)
    vim.cmd('startinsert!')
  end
end

-- SECTION 7: Input handling ----------------------------------------------
local function _get_query()
  if not state.prompt_buf or not vim.api.nvim_buf_is_valid(state.prompt_buf) then
    return ''
  end
  local lines = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, 1, false)
  local line = lines[1] or ''
  -- prompt prefix ("> ") を除去
  return line:gsub('^> ', '')
end

local grep_debounced = nil

local function _reload_files()
  if state.source_name ~= 'files' then
    return
  end
  if state.async_job then
    pcall(function()
      state.async_job:kill(9)
    end)
    state.async_job = nil
  end
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  _render_list()
  local title = state.no_ignore and 'files [no-ignore]' or 'files'
  pcall(vim.api.nvim_win_set_config, state.prompt_win, {
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  })
  local job = sources.files.load(function(items)
    if state.source_name ~= 'files' then
      return
    end
    state.all_items = items
    local q = _get_query()
    state.filtered = sources.files.filter(items, q)
    state.cursor_idx = 1
    _render_list()
    _update_cursor()
    if state.use_preview and #state.filtered > 0 then
      M._update_preview(state.filtered[1])
    end
  end)
  state.async_job = job
end

local function _run_grep(query)
  if state.source_name ~= 'grep' then
    return
  end

  -- 既存ジョブを停止
  if state.async_job then
    pcall(function()
      state.async_job:kill(9)
    end)
    state.async_job = nil
  end

  if query == '' then
    state.all_items = {}
    state.filtered = {}
    state.cursor_idx = 1
    _render_list()
    return
  end

  local items = {}
  local job = vim.system({ 'rg', '--vimgrep', '--', query }, { text = true }, function(result)
    if result.stdout then
      for line in result.stdout:gmatch('[^\n]+') do
        table.insert(items, { text = line })
      end
    end
    vim.schedule(function()
      if state.source_name ~= 'grep' then
        return
      end
      state.all_items = items
      state.filtered = items
      state.cursor_idx = 1
      _render_list()
      _update_cursor()
      if state.use_preview and #items > 0 then
        M._update_preview(items[1])
      end
    end)
  end)
  state.async_job = job
end

local function _on_query_change()
  local query = _get_query()
  local src = state.source_name

  if src == 'grep' then
    if grep_debounced == nil then
      grep_debounced = debounce(_run_grep, M.config.debounce_ms)
    end
    grep_debounced(query)
    return
  end

  if src == 'tree' then
    if query == '' then
      state.filtered = tree_flatten()
    elseif state.tree_all_files then
      local r = vim.fn.matchfuzzypos(state.tree_all_files, query, { key = 'text' })
      state.filtered = tree_build_filtered(r[1])
    end
    state.all_items = state.filtered
    state.cursor_idx = 1
    _render_list()
    _update_cursor()
    if state.use_preview and #state.filtered > 0 then
      M._update_preview(state.filtered[1])
    end
    return
  end

  -- files / buffers / buf_lines: matchfuzzy でフィルタ
  local source_def
  if src == 'files' then
    source_def = sources.files
  elseif src == 'buffers' then
    source_def = sources.buffers
  elseif src == 'buf_lines' then
    source_def = sources.buf_lines
  elseif src == 'select' then
    if query == '' then
      state.filtered = state.all_items
    else
      local r = vim.fn.matchfuzzypos(state.all_items, query, { key = 'text' })
      local matched, positions = r[1], r[2]
      for i = 1, #matched do
        matched[i]._match_pos = positions[i]
      end
      state.filtered = matched
    end
    state.cursor_idx = 1
    _render_list()
    _update_cursor()
    return
  end

  if source_def then
    state.filtered = source_def.filter(state.all_items, query)
    state.cursor_idx = 1
    _render_list()
    _update_cursor()
    if state.use_preview and #state.filtered > 0 then
      M._update_preview(state.filtered[1])
    end
  end
end

local function _setup_autocmds()
  local aug = vim.api.nvim_create_augroup('picker_autocmds', { clear = true })
  state._augroup = aug

  -- 入力変化を検知
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    group = aug,
    buffer = state.prompt_buf,
    callback = function()
      _on_query_change()
    end,
  })

  -- picker 以外にフォーカスが移ったら閉じる
  vim.api.nvim_create_autocmd('WinLeave', {
    group = aug,
    callback = function()
      vim.schedule(function()
        local cur = vim.api.nvim_get_current_win()
        if
          cur ~= state.prompt_win
          and cur ~= state.list_win
          and cur ~= (state.preview_win or -1)
        then
          M.close()
        end
      end)
    end,
  })

  -- tree nav: カーソル移動でプレビュー更新
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = aug,
    buffer = state.list_buf,
    callback = function()
      if state.tree_nav_mode and state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
        local cursor = vim.api.nvim_win_get_cursor(state.list_win)
        state.cursor_idx = cursor[1]
        if state.use_preview and state.filtered[state.cursor_idx] then
          M._update_preview(state.filtered[state.cursor_idx])
        end
      end
    end,
  })
end

-- SECTION 8: Keymaps -----------------------------------------------------
local function set_prompt_keymaps()
  local buf = state.prompt_buf
  local opts = { noremap = true, silent = true, buffer = buf }

  -- カーソル移動
  vim.keymap.set('i', '<C-n>', function()
    _move_cursor(1)
  end, opts)
  vim.keymap.set('i', '<Down>', function()
    _move_cursor(1)
  end, opts)
  vim.keymap.set('i', '<C-p>', function()
    _move_cursor(-1)
  end, opts)
  vim.keymap.set('i', '<Up>', function()
    _move_cursor(-1)
  end, opts)

  -- 確定
  vim.keymap.set('i', '<CR>', function()
    M._accept()
  end, opts)
  vim.keymap.set('i', '<C-v>', function()
    M._accept_with_split('vsplit')
  end, opts)
  vim.keymap.set('i', '<C-x>', function()
    M._accept_with_split('split')
  end, opts)

  -- 閉じる
  vim.keymap.set('i', '<Esc>', function()
    if state.source_name == 'tree' then
      tree_enter_nav_mode()
    else
      M.close()
    end
  end, opts)
  vim.keymap.set('i', '<C-c>', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<C-c>', function()
    M.close()
  end, opts)

  -- gitignore トグル（files ソースのみ）
  vim.keymap.set('i', '<C-i>', function()
    if state.source_name == 'files' then
      state.no_ignore = not state.no_ignore
      _reload_files()
    end
  end, opts)

  -- テキスト移動（mappings.lua と同じ挙動）
  vim.keymap.set('i', '<C-b>', '<Left>', opts)
  vim.keymap.set('i', '<C-f>', '<Right>', opts)
  vim.keymap.set('i', '<C-a>', '<Home>', opts)
  vim.keymap.set('i', '<C-e>', '<End>', opts)
  vim.keymap.set('i', '<C-h>', '<BS>', opts)
end

local function set_tree_nav_keymaps()
  local buf = state.list_buf
  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    _move_cursor(1)
  end, opts)
  vim.keymap.set('n', 'k', function()
    _move_cursor(-1)
  end, opts)
  vim.keymap.set('n', 'l', function()
    tree_expand()
  end, opts)
  vim.keymap.set('n', 'h', function()
    tree_collapse()
  end, opts)
  vim.keymap.set('n', '<CR>', function()
    local item = state.filtered[state.cursor_idx]
    if item and item._tree_node and item._tree_node.is_dir then
      if state.tree_open_dirs[item._tree_node.path] then
        tree_collapse()
      else
        tree_expand()
      end
    else
      M._accept()
    end
  end, opts)
  vim.keymap.set('n', '/', function()
    tree_enter_search_mode()
  end, opts)
  vim.keymap.set('n', 'i', function()
    tree_enter_search_mode()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)
  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<C-v>', function()
    M._accept_with_split('vsplit')
  end, opts)
  vim.keymap.set('n', '<C-x>', function()
    M._accept_with_split('split')
  end, opts)
end

-- SECTION 9: Core --------------------------------------------------------
function M._accept_with_split(split_cmd)
  local item = state.filtered[state.cursor_idx]
  local src = state.source_name or ''
  local on_select = state.on_select
  local origin_buf = state.origin_buf -- close() 前に保存
  M.close()

  if not item then
    return
  end

  -- vim.ui.select はスプリット非対応（通常の選択として扱う）
  if on_select then
    on_select(item)
    return
  end

  if src == 'tree' then
    if item._tree_node and item._tree_node.is_dir then
      return
    end
    vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
    return
  end

  if src == 'files' or src == 'select' then
    vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
    return
  end

  if src == 'buffers' then
    if item.buf then
      vim.cmd(split_cmd)
      vim.api.nvim_set_current_buf(item.buf)
    else
      vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
    end
    return
  end

  if src == 'grep' then
    local path, lnum = item.text:match('^([^:]+):(%d+):')
    if path then
      vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(path))
      if lnum then
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
      end
    end
    return
  end

  if src == 'buf_lines' then
    if origin_buf and vim.api.nvim_buf_is_valid(origin_buf) then
      vim.cmd(split_cmd)
      vim.api.nvim_set_current_buf(origin_buf)
      if item.lnum then
        vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
      end
    end
    return
  end
end

function M._accept()
  local item = state.filtered[state.cursor_idx]
  -- close() より先に取り出す（close() で nil にリセットされるため）
  local src = state.source_name or ''
  local on_select = state.on_select
  M.close()

  if not item then
    return
  end

  -- vim.ui.select
  if on_select then
    on_select(item)
    return
  end

  -- tree
  if src == 'tree' then
    if item._tree_node and item._tree_node.is_dir then
      return
    end
    vim.cmd.edit(item.text)
    return
  end

  -- files
  if src == 'files' or src == 'select' then
    vim.cmd.edit(item.text)
    return
  end

  -- buffers
  if src == 'buffers' then
    if item.buf then
      vim.api.nvim_set_current_buf(item.buf)
    else
      vim.cmd.edit(item.text)
    end
    return
  end

  -- grep: "file:lnum:col:text"
  if src == 'grep' then
    local path, lnum = item.text:match('^([^:]+):(%d+):')
    if path then
      vim.cmd.edit(path)
      if lnum then
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
      end
    end
    return
  end

  -- buf_lines
  if src == 'buf_lines' then
    if item.lnum then
      vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
    end
    return
  end
end

function M.open(source_name, opts)
  opts = opts or {}

  -- 既に開いていれば閉じる
  if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
    M.close()
  end

  state.origin_win = vim.api.nvim_get_current_win()
  state.origin_buf = vim.api.nvim_get_current_buf()
  state.source_name = source_name
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.on_select = opts.on_select or nil
  grep_debounced = nil

  local source_def = sources[source_name]
  local use_preview = false
  if source_def then
    use_preview = source_def.use_preview or false
  end
  state.use_preview = use_preview

  local layout = calc_layout()
  local title = opts.title or source_name
  local footer = (source_name == 'files') and '<C-i>: toggle ignore' or nil

  local prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win =
    _create_windows(layout, title, use_preview, footer)

  state.prompt_buf = prompt_buf
  state.prompt_win = prompt_win
  state.list_buf = list_buf
  state.list_win = list_win
  state.preview_buf = preview_buf
  state.preview_win = preview_win

  -- prompt を Insert mode で開始
  vim.fn.prompt_setprompt(prompt_buf, '> ')
  vim.api.nvim_set_current_win(prompt_win)
  vim.cmd('startinsert!')

  set_prompt_keymaps()
  _setup_autocmds()

  -- アイテム読み込み
  if source_name == 'tree' then
    state.tree_root = { name = '.', path = '.', is_dir = true, children = nil }
    state.tree_open_dirs = {}
    state.tree_all_files = nil
    state.tree_nav_mode = false
    tree_ensure_children(state.tree_root)
    local items = tree_flatten()
    state.all_items = items
    state.filtered = items
    _render_list()
    _update_cursor()
    if use_preview and #items > 0 then
      M._update_preview(items[1])
    end
    set_tree_nav_keymaps()
    tree_load_all_files()
    tree_enter_nav_mode()
  elseif opts.items then
    -- vim.ui.select 用: 直接アイテムを渡す
    state.all_items = opts.items
    state.filtered = opts.items
    _render_list()
    _update_cursor()
  elseif source_def then
    local job = source_def.load(function(items)
      if state.source_name ~= source_name then
        return
      end
      state.all_items = items
      -- 初期クエリでフィルタ
      local q = _get_query()
      if q ~= '' then
        state.filtered = source_def.filter(items, q)
      else
        state.filtered = items
      end
      state.cursor_idx = 1
      _render_list()
      _update_cursor()
      if use_preview and #state.filtered > 0 then
        M._update_preview(state.filtered[1])
      end
    end)
    state.async_job = job
  end
end

-- SECTION 10: Public API -------------------------------------------------
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, opts, on_choice)
    M.ui_select(items, opts, on_choice)
  end
  vim.keymap.set('n', '<Leader>f', function()
    M.files()
  end, { desc = 'picker: files' })
  vim.keymap.set('n', '<Leader>b', function()
    M.buffers()
  end, { desc = 'picker: buffers' })
  vim.keymap.set('n', '<Leader>G', function()
    M.grep()
  end, { desc = 'picker: grep' })
  vim.keymap.set('n', '<Leader>l', function()
    M.buf_lines()
  end, { desc = 'picker: buf_lines' })
  vim.keymap.set('n', '<Leader>e', function()
    M.tree()
  end, { desc = 'picker: tree' })
end

function M.files()
  M.open('files', { title = 'files' })
end

function M.buffers()
  M.open('buffers', { title = 'buffers' })
end

function M.grep()
  M.open('grep', { title = 'grep' })
end

function M.buf_lines()
  M.open('buf_lines', { title = 'buf_lines' })
end

function M.tree()
  M.open('tree', { title = 'tree' })
end

function M.ui_select(items, opts, on_choice)
  if type(opts) == 'function' and on_choice == nil then
    on_choice = opts
    opts = nil
  end
  opts = opts or {}
  on_choice = on_choice or function() end

  if type(items) ~= 'table' then
    if original_ui_select then
      return original_ui_select(items, opts, on_choice)
    end
    return on_choice(nil)
  end

  local picker_items = vim.tbl_map(function(i)
    return { text = (opts.format_item or tostring)(i), value = i }
  end, items)
  M.open('select', {
    title = opts.prompt or 'select',
    items = picker_items,
    on_select = function(picked)
      on_choice(picked and picked.value or nil)
    end,
  })
end

return M
