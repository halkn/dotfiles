-- picker.lua: 自前 fuzzy finder
-- telescope/snacks 風の floating window UI
local M = {}
local original_ui_select = vim.ui.select

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
  local w = math.floor(total_w * 0.9)
  local h = math.floor(total_h * 0.8)
  local row = math.floor((total_h - h) / 2)
  local col = math.floor((total_w - w) / 2)
  return { w = w, h = h, row = row, col = col }
end

-- SECTION 3: Sources -----------------------------------------------------

-- アイコン取得（mini.icons → nvim-web-devicons → nil の順に試みる）
-- 必ずメインスレッド（vim.schedule内）から呼ぶこと
local _icon_fn = nil
local function get_icon(filepath)
  if _icon_fn == false then
    return nil
  end
  if _icon_fn == nil then
    local ok, icons = pcall(require, 'mini.icons')
    if ok and icons.get then
      -- setup() 未呼び出しの場合に備えて初期化を試みる
      if not icons.config then
        pcall(icons.setup, {})
      end
      _icon_fn = function(p)
        local ok2, icon = pcall(icons.get, 'file', p)
        -- 成功かつ空文字でなければ返す
        if ok2 and icon and icon ~= '' then
          return icon
        end
        return nil
      end
    else
      local ok2, devicons = pcall(require, 'nvim-web-devicons')
      if ok2 then
        _icon_fn = function(p)
          local ext = vim.fn.fnamemodify(p, ':e')
          return devicons.get_icon(p, ext)
        end
      else
        _icon_fn = false
        return nil
      end
    end
  end
  return _icon_fn(filepath)
end

local sources = {}

sources.files = {
  name = 'files',
  use_preview = true,
  load = function(callback)
    local items = {}
    local job = vim.system(
      { 'rg', '--files', '--hidden', '--glob', '!**/.git/*' },
      { text = true },
      function(result)
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
      end
    )
    return job
  end,
  filter = function(items, query)
    if query == '' then
      return items
    end
    return vim.fn.matchfuzzy(items, query, { key = 'text' })
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
    return vim.fn.matchfuzzy(items, query, { key = 'text' })
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
    return vim.fn.matchfuzzy(items, query, { key = 'text' })
  end,
}

-- SECTION 4: Window management -------------------------------------------
local function _create_windows(layout, title, use_preview)
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
  })
  vim.wo[list_win].wrap = false
  vim.wo[list_win].cursorline = true
  vim.wo[list_win].winhighlight = 'CursorLine:PmenuSel,CursorLineBg:PmenuSel'

  return prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win
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
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    state[win_key] = nil
  end
  for _, buf_key in ipairs({ 'prompt_buf', 'list_buf', 'preview_buf' }) do
    local buf = state[buf_key]
    if buf and vim.api.nvim_buf_is_valid(buf) then
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

  if origin and vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
end

-- SECTION 5: List rendering ----------------------------------------------
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
    vim.api.nvim_buf_add_highlight(state.preview_buf, -1, 'CursorLine', safe_lnum - 1, 0, -1)
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
  if src == 'files' then
    M._preview_file(item.text, nil)
  elseif src == 'grep' then
    -- grep: "file:lnum:col:text" 形式
    local path, lnum = item.text:match('^([^:]+):(%d+):')
    if path then
      M._preview_file(path, tonumber(lnum))
    end
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
      grep_debounced = debounce(_run_grep, 150)
    end
    grep_debounced(query)
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
    -- select は matchfuzzy を使う
    state.filtered = (query == '') and state.all_items
      or vim.fn.matchfuzzy(state.all_items, query, { key = 'text' })
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
      local current = vim.api.nvim_get_current_win()
      if
        current ~= state.prompt_win
        and current ~= state.list_win
        and current ~= state.preview_win
      then
        M.close()
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
    M.close()
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

  -- テキスト移動（mappings.lua と同じ挙動）
  vim.keymap.set('i', '<C-b>', '<Left>', opts)
  vim.keymap.set('i', '<C-f>', '<Right>', opts)
  vim.keymap.set('i', '<C-a>', '<Home>', opts)
  vim.keymap.set('i', '<C-e>', '<End>', opts)
  vim.keymap.set('i', '<C-h>', '<BS>', opts)
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

  local prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win =
    _create_windows(layout, title, use_preview)

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
  if opts.items then
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
function M.setup()
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
