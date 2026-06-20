local M = {}
local win = require('vimrc.modules.picker.window')
local original_ui_select = vim.ui.select
local preview_ns = vim.api.nvim_create_namespace('vimrc_picker_preview')
local match_ns = vim.api.nvim_create_namespace('vimrc_picker_match')

vim.api.nvim_set_hl(0, 'PickerMatch', { link = 'Special' })

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

local state = {
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
  _augroup = nil,
  no_ignore = false,
  _on_esc = nil,
  _on_cursor_moved = nil,
}

local sources = {
  files = require('vimrc.modules.picker.sources.files'),
  buffers = require('vimrc.modules.picker.sources.buffers'),
  grep = require('vimrc.modules.picker.sources.grep'),
  buf_lines = require('vimrc.modules.picker.sources.buf_lines'),
  tree = require('vimrc.modules.picker.sources.tree'),
  select = require('vimrc.modules.picker.sources.select'),
}

-- Utilities ------------------------------------------------------------------

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

local function default_filter(items, query)
  if query == '' then
    return items
  end
  local r = vim.fn.matchfuzzypos(items, query, { key = 'text' })
  local matched, positions = r[1], r[2]
  for i = 1, #matched do
    matched[i]._match_pos = positions[i]
  end
  return matched
end

-- List rendering -------------------------------------------------------------

local function _apply_match_highlights()
  if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.list_buf, match_ns, 0, -1)
  local source_def = state.source_def
  local use_source_offset = source_def and source_def.match_highlight_offset
  for i, item in ipairs(state.filtered) do
    if item._match_pos then
      local display = item.display or item.text
      local offset = (use_source_offset and source_def) and source_def.match_highlight_offset()
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

-- Preview --------------------------------------------------------------------

local function _preview_file(path, lnum)
  if not state.preview_buf or not vim.api.nvim_buf_is_valid(state.preview_buf) then
    return
  end

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

  for i, line in ipairs(lines) do
    lines[i] = line:gsub('[\n\r]', '')
  end

  vim.bo[state.preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
  vim.bo[state.preview_buf].modifiable = false

  local ft = vim.filetype.match({ filename = path })
  if ft then
    vim.bo[state.preview_buf].filetype = ft
    pcall(vim.treesitter.start, state.preview_buf, ft)
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

local function _clear_preview()
  if state.preview_buf and vim.api.nvim_buf_is_valid(state.preview_buf) then
    vim.bo[state.preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, {})
    vim.bo[state.preview_buf].modifiable = false
  end
end

local function _update_preview_current()
  if not state.use_preview then
    return
  end
  local item = state.filtered[state.cursor_idx]
  if not item then
    return
  end
  local source_def = state.source_def
  if source_def and source_def.update_preview then
    local result = source_def.update_preview(item, _preview_file)
    if result == 'clear' then
      _clear_preview()
    end
  elseif source_def and source_def.preview_file then
    local path, lnum = source_def.preview_file(item)
    if path then
      _preview_file(path, lnum)
    end
  else
    _preview_file(item.text, nil)
  end
end

-- Cursor movement ------------------------------------------------------------

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
  _update_preview_current()
end

-- Close ----------------------------------------------------------------------

function M.close()
  if state._augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state._augroup)
    state._augroup = nil
  end

  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer:close()
    state.debounce_timer = nil
  end

  if state.async_job then
    pcall(function()
      state.async_job:kill(9)
    end)
    state.async_job = nil
  end

  local source_def = state.source_def
  if source_def and source_def.on_close then
    source_def.on_close()
  end

  for _, win_key in ipairs({ 'prompt_win', 'list_win', 'preview_win' }) do
    local w = state[win_key]
    if type(w) == 'number' and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_close(w, true)
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

  local origin = state.origin_win
  state.origin_win = nil
  state.origin_buf = nil
  state.on_select = nil
  state.source_name = nil
  state.source_def = nil
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.use_preview = false
  state.no_ignore = false
  state._on_esc = nil
  state._on_cursor_moved = nil
  win.restore_cursor()

  if origin and vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
end

-- Accept ---------------------------------------------------------------------

function M._accept()
  local item = state.filtered[state.cursor_idx]
  local source_def = state.source_def
  local on_select = state.on_select
  M.close()

  if not item then
    return
  end

  if on_select then
    on_select(item)
    return
  end

  if source_def and source_def.on_accept then
    source_def.on_accept(item)
  end
end

function M._accept_with_split(split_cmd)
  local item = state.filtered[state.cursor_idx]
  local source_def = state.source_def
  local on_select = state.on_select
  local origin_buf = state.origin_buf
  M.close()

  if not item then
    return
  end

  if on_select then
    on_select(item)
    return
  end

  if source_def and source_def.on_accept_split then
    source_def.on_accept_split(item, split_cmd, origin_buf)
  end
end

-- Source context (passed to sources) -----------------------------------------

local function _build_source_ctx()
  return {
    list_buf = state.list_buf,
    async_job = state.async_job,
    set_items = function(all, filtered)
      state.all_items = all
      state.filtered = filtered
    end,
    set_cursor_idx = function(idx)
      state.cursor_idx = idx
    end,
    clamp_cursor = function()
      state.cursor_idx = math.min(state.cursor_idx, math.max(1, #state.filtered))
    end,
    get_current_item = function()
      return state.filtered[state.cursor_idx]
    end,
    render = _render_list,
    update_cursor = _update_cursor,
    update_preview = _update_preview_current,
    move_cursor = _move_cursor,
    accept = function()
      M._accept()
    end,
    accept_split = function(split_cmd)
      M._accept_with_split(split_cmd)
    end,
    close = function()
      M.close()
    end,
    jump_to_text = function(text)
      for i, it in ipairs(state.filtered) do
        if it.text == text then
          state.cursor_idx = i
          _update_cursor()
          _update_preview_current()
          break
        end
      end
    end,
    focus_list = function()
      if state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
        vim.api.nvim_set_current_win(state.list_win)
        vim.cmd('stopinsert')
      end
    end,
    focus_prompt = function()
      if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
        vim.api.nvim_set_current_win(state.prompt_win)
        vim.cmd('startinsert!')
      end
    end,
    switch_source = function(name)
      M._switch_source(name)
    end,
    set_on_esc = function(fn)
      state._on_esc = fn
    end,
    set_on_cursor_moved = function(fn)
      state._on_cursor_moved = fn
    end,
  }
end

-- Input handling -------------------------------------------------------------

local function _get_query()
  if not state.prompt_buf or not vim.api.nvim_buf_is_valid(state.prompt_buf) then
    return ''
  end
  local lines = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, 1, false)
  local line = lines[1] or ''
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
  local source_def = state.source_def
  if not source_def then
    return
  end
  local job = source_def.load(M.config, { no_ignore = state.no_ignore }, function(items)
    if state.source_name ~= 'files' then
      return
    end
    state.all_items = items
    local q = _get_query()
    state.filtered = default_filter(items, q)
    state.cursor_idx = 1
    _render_list()
    _update_cursor()
    _update_preview_current()
  end)
  state.async_job = job
end

local function _on_query_change()
  local query = _get_query()
  local source_def = state.source_def

  if source_def and source_def.on_query_change then
    local ctx = _build_source_ctx()
    if state.source_name == 'grep' then
      if grep_debounced == nil then
        grep_debounced = debounce(function(q)
          local fresh_ctx = _build_source_ctx()
          source_def.on_query_change(q, fresh_ctx)
        end, M.config.debounce_ms)
      end
      grep_debounced(query)
    else
      source_def.on_query_change(query, ctx)
    end
    return
  end

  local filter_fn = (source_def and source_def.filter) or default_filter
  state.filtered = filter_fn(state.all_items, query)
  state.cursor_idx = 1
  _render_list()
  _update_cursor()
  _update_preview_current()
end

-- Source switching ------------------------------------------------------------

function M._switch_source(target_name)
  local target_def = sources[target_name]
  if not target_def then
    return
  end

  if state.async_job then
    pcall(function()
      state.async_job:kill(9)
    end)
    state.async_job = nil
  end

  local current_def = state.source_def
  if current_def and current_def.on_close then
    current_def.on_close()
  end

  -- clear prompt
  if state.prompt_buf and vim.api.nvim_buf_is_valid(state.prompt_buf) then
    vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { '> ' })
  end

  state.source_name = target_name
  state.source_def = target_def
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.no_ignore = false
  state._on_esc = nil
  state._on_cursor_moved = nil
  grep_debounced = nil

  local title = target_name
  local footer = (target_name == 'files') and '<C-i>: toggle ignore | <C-t>: tree' or nil
  if target_name == 'tree' then
    footer = '<C-t>: files'
  end
  pcall(vim.api.nvim_win_set_config, state.prompt_win, {
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  })
  pcall(vim.api.nvim_win_set_config, state.list_win, {
    footer = footer and (' ' .. footer .. ' ') or nil,
    footer_pos = footer and 'right' or nil,
  })

  if target_def.on_open then
    local ctx = _build_source_ctx()
    target_def.on_open(ctx)
    local job = target_def.load(M.config, {}, function() end)
    state.async_job = job
  else
    local load_opts = { origin_buf = state.origin_buf, no_ignore = state.no_ignore }
    local job = target_def.load(M.config, load_opts, function(items)
      if state.source_name ~= target_name then
        return
      end
      state.all_items = items
      state.filtered = items
      state.cursor_idx = 1
      _render_list()
      _update_cursor()
      _update_preview_current()
    end)
    state.async_job = job

    win.restore_cursor()
    if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
      vim.api.nvim_set_current_win(state.prompt_win)
      vim.cmd('startinsert!')
    end
  end
end

-- Autocmds -------------------------------------------------------------------

local function _setup_autocmds()
  local aug = vim.api.nvim_create_augroup('picker_autocmds', { clear = true })
  state._augroup = aug

  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    group = aug,
    buffer = state.prompt_buf,
    callback = _on_query_change,
  })

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

  vim.api.nvim_create_autocmd('CursorMoved', {
    group = aug,
    buffer = state.list_buf,
    callback = function()
      if
        state._on_cursor_moved
        and state.list_win
        and vim.api.nvim_win_is_valid(state.list_win)
      then
        local cursor = vim.api.nvim_win_get_cursor(state.list_win)
        state._on_cursor_moved(cursor[1])
      end
    end,
  })
end

-- Keymaps --------------------------------------------------------------------

local function _set_prompt_keymaps()
  local buf = state.prompt_buf
  local opts = { noremap = true, silent = true, buffer = buf }

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

  vim.keymap.set('i', '<CR>', function()
    M._accept()
  end, opts)
  vim.keymap.set('i', '<C-v>', function()
    M._accept_with_split('vsplit')
  end, opts)
  vim.keymap.set('i', '<C-x>', function()
    M._accept_with_split('split')
  end, opts)

  vim.keymap.set('i', '<Esc>', function()
    if state._on_esc then
      state._on_esc()
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

  vim.keymap.set('i', '<C-i>', function()
    if state.source_name == 'files' then
      state.no_ignore = not state.no_ignore
      _reload_files()
    end
  end, opts)

  vim.keymap.set('i', '<C-t>', function()
    if state.source_name == 'files' then
      M._switch_source('tree')
    elseif state.source_name == 'tree' then
      M._switch_source('files')
    end
  end, opts)

  vim.keymap.set('i', '<C-b>', '<Left>', opts)
  vim.keymap.set('i', '<C-f>', '<Right>', opts)
  vim.keymap.set('i', '<C-a>', '<Home>', opts)
  vim.keymap.set('i', '<C-e>', '<End>', opts)
  vim.keymap.set('i', '<C-h>', '<BS>', opts)
end

-- Open -----------------------------------------------------------------------

function M.open(source_name, opts)
  opts = opts or {}

  if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
    M.close()
  end

  local source_def = sources[source_name]
  state.origin_win = vim.api.nvim_get_current_win()
  state.origin_buf = vim.api.nvim_get_current_buf()
  state.source_name = source_name
  state.source_def = source_def
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.on_select = opts.on_select or nil
  grep_debounced = nil

  local use_preview = source_def and source_def.use_preview or false
  state.use_preview = use_preview

  local layout = win.calc_layout(M.config)
  local title = opts.title or source_name
  local footer = nil
  if source_name == 'files' then
    footer = '<C-i>: toggle ignore | <C-t>: tree'
  elseif source_name == 'tree' then
    footer = '<C-t>: files'
  end

  local prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win =
    win.create_windows(layout, title, use_preview, footer)

  state.prompt_buf = prompt_buf
  state.prompt_win = prompt_win
  state.list_buf = list_buf
  state.list_win = list_win
  state.preview_buf = preview_buf
  state.preview_win = preview_win

  vim.fn.prompt_setprompt(prompt_buf, '> ')
  vim.api.nvim_set_current_win(prompt_win)
  vim.cmd('startinsert!')

  _set_prompt_keymaps()
  _setup_autocmds()

  if source_def and source_def.on_open then
    local ctx = _build_source_ctx()
    source_def.on_open(ctx)
    local job = source_def.load(M.config, {}, function() end)
    state.async_job = job
  elseif opts.items then
    state.all_items = opts.items
    state.filtered = opts.items
    _render_list()
    _update_cursor()
  elseif source_def then
    local load_opts = { origin_buf = state.origin_buf, no_ignore = state.no_ignore }
    local job = source_def.load(M.config, load_opts, function(items)
      if state.source_name ~= source_name then
        return
      end
      state.all_items = items
      local q = _get_query()
      if q ~= '' then
        local filter_fn = source_def.filter or default_filter
        state.filtered = filter_fn(items, q)
      else
        state.filtered = items
      end
      state.cursor_idx = 1
      _render_list()
      _update_cursor()
      _update_preview_current()
    end)
    state.async_job = job
  end
end

-- Public API -----------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, select_opts, on_choice)
    M.ui_select(items, select_opts, on_choice)
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
