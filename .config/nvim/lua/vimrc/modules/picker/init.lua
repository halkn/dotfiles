local M = {}
local picker_state = require('vimrc.modules.picker.state')
local ui = require('vimrc.modules.picker.ui')
local preview = require('vimrc.modules.picker.preview')
local select = require('vimrc.modules.picker.select')
local win = require('vimrc.modules.picker.window')

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

local state = picker_state.new()
local sources = {
  files = require('vimrc.modules.picker.sources.files'),
  buffers = require('vimrc.modules.picker.sources.buffers'),
  grep = require('vimrc.modules.picker.sources.grep'),
  buf_lines = require('vimrc.modules.picker.sources.buf_lines'),
  tree = require('vimrc.modules.picker.sources.tree'),
  git = require('vimrc.modules.picker.sources.git'),
  select = require('vimrc.modules.picker.sources.select'),
}

local function is_active(generation, source_name)
  return state.generation == generation and state.source_name == source_name
end

local function update_preview()
  preview.update_current(state)
end

local function close_source(source)
  if source and source.on_close then
    source.on_close()
  end
end

function M.close()
  local origin = state.origin_win
  picker_state.cleanup(state, close_source)
  win.restore_cursor()
  if origin and vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
end

local function accept()
  local item = state.filtered[state.cursor_idx]
  local source = state.source_def
  local on_select = state.on_select
  M.close()
  if not item then
    return
  end
  if on_select then
    on_select(item)
  elseif source and source.on_accept then
    source.on_accept(item)
  end
end

local function accept_with_split(split_cmd)
  local item = state.filtered[state.cursor_idx]
  local source = state.source_def
  local on_select = state.on_select
  local origin_buf = state.origin_buf
  M.close()
  if not item then
    return
  end
  if on_select then
    on_select(item)
  elseif source and source.on_accept_split then
    source.on_accept_split(item, split_cmd, origin_buf)
  end
end

local function source_title(source, fallback)
  local title = source and source.title and source.title(state.source_opts)
  return title or fallback
end

local function apply_window_decorations(source, title)
  pcall(vim.api.nvim_win_set_config, state.prompt_win, {
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  })
  local footer = source and source.footer
  pcall(vim.api.nvim_win_set_config, state.list_win, {
    footer = footer and (' ' .. footer .. ' ') or nil,
    footer_pos = footer and 'right' or nil,
  })
end

local function load_opts()
  return vim.tbl_extend('force', { origin_buf = state.origin_buf }, state.source_opts)
end

local function on_loaded(generation, source_name, source)
  return function(items)
    if not is_active(generation, source_name) then
      return
    end
    state.all_items = items
    local query = ui.get_query(state)
    state.filtered = query == '' and items or (source.filter or ui.default_filter)(items, query)
    state.cursor_idx = 1
    ui.render_list(state)
    ui.update_cursor(state)
    update_preview()
  end
end

local function reload()
  local source, source_name = state.source_def, state.source_name
  if not source then
    return
  end
  local generation = picker_state.begin(state)
  picker_state.cancel_job(state)
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  ui.render_list(state)
  apply_window_decorations(source, source_title(source, source_name))
  picker_state.set_job(
    state,
    source.load(M.config, load_opts(), on_loaded(generation, source_name, source))
  )
end

-- Source contract:
--   required: name, load(config, options, callback)
--   optional: filter, footer, title, keymaps, debounce_query, on_open, on_close,
--   on_query_change, on_accept, on_accept_split, preview_file, update_preview,
--   match_highlight_offset.
local function build_source_context()
  return {
    list_buf = state.list_buf,
    set_items = function(all, filtered)
      state.all_items = all
      state.filtered = filtered
    end,
    set_job = function(job)
      picker_state.set_job(state, job)
    end,
    cancel_job = function()
      picker_state.cancel_job(state)
    end,
    is_current_job = function(job)
      return state.async_job == job
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
    render = function()
      ui.render_list(state)
    end,
    update_cursor = function()
      ui.update_cursor(state)
    end,
    update_preview = update_preview,
    move_cursor = function(delta)
      ui.move_cursor(state, delta, update_preview)
    end,
    accept = accept,
    accept_split = accept_with_split,
    close = M.close,
    jump_to_text = function(text)
      for i, item in ipairs(state.filtered) do
        if item.text == text then
          state.cursor_idx = i
          ui.update_cursor(state)
          update_preview()
          break
        end
      end
    end,
    focus_list = function()
      ui.focus_list(state)
    end,
    focus_prompt = function()
      ui.focus_prompt(state)
    end,
    switch_source = function(name)
      M._switch_source(name)
    end,
    get_opt = function(key)
      return state.source_opts[key]
    end,
    set_opt = function(key, value)
      state.source_opts[key] = value
    end,
    reload = reload,
    set_on_esc = function(callback)
      state.on_esc = callback
    end,
    set_on_cursor_moved = function(callback)
      state.on_cursor_moved = callback
    end,
  }
end

local function debounce(callback)
  return function(query)
    local timer = vim.uv.new_timer()
    picker_state.set_timer(state, timer)
    timer:start(
      M.config.debounce_ms,
      0,
      vim.schedule_wrap(function()
        if state.debounce_timer == timer then
          picker_state.cancel_timer(state)
          callback(query)
        end
      end)
    )
  end
end

local query_debounced

local function on_query_change()
  local source = state.source_def
  local query = ui.get_query(state)
  if source and source.on_query_change then
    if source.debounce_query then
      if not query_debounced then
        query_debounced = debounce(function(debounced_query)
          source.on_query_change(debounced_query, build_source_context())
        end)
      end
      query_debounced(query)
    else
      source.on_query_change(query, build_source_context())
    end
    return
  end

  local filter = source and source.filter or ui.default_filter
  state.filtered = filter(state.all_items, query)
  state.cursor_idx = 1
  ui.render_list(state)
  ui.update_cursor(state)
  update_preview()
end

local source_keymap_lhs = {}

local function set_source_keymaps(source)
  if state.prompt_buf and vim.api.nvim_buf_is_valid(state.prompt_buf) then
    for _, lhs in ipairs(source_keymap_lhs) do
      pcall(vim.keymap.del, 'i', lhs, { buffer = state.prompt_buf })
    end
  end
  source_keymap_lhs = {}
  if not source.keymaps then
    return
  end
  local opts = { noremap = true, silent = true, buffer = state.prompt_buf }
  for lhs, callback in pairs(source.keymaps) do
    vim.keymap.set('i', lhs, function()
      callback(build_source_context())
    end, opts)
    table.insert(source_keymap_lhs, lhs)
  end
end

local function start_source(source_name, source, opts)
  local generation = picker_state.begin(state)
  state.source_name = source_name
  state.source_def = source
  state.all_items = {}
  state.filtered = {}
  state.cursor_idx = 1
  state.source_opts = {}
  state.on_esc = nil
  state.on_cursor_moved = nil
  query_debounced = nil

  apply_window_decorations(source, opts.title or source_title(source, source_name))
  set_source_keymaps(source)

  if source.on_open then
    source.on_open(build_source_context())
  end
  if opts.items then
    state.all_items = opts.items
    state.filtered = opts.items
    ui.render_list(state)
    ui.update_cursor(state)
    return
  end
  picker_state.set_job(
    state,
    source.load(M.config, load_opts(), on_loaded(generation, source_name, source))
  )
end

function M._switch_source(target_name)
  local target = sources[target_name]
  if not target then
    return
  end
  picker_state.cancel_job(state)
  close_source(state.source_def)

  if state.prompt_buf and vim.api.nvim_buf_is_valid(state.prompt_buf) then
    vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { '> ' })
  end
  start_source(target_name, target, {})

  if not target.on_open then
    win.restore_cursor()
    ui.focus_prompt(state)
  end
end

local function setup_autocmds()
  state.augroup = vim.api.nvim_create_augroup('picker_autocmds', { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    group = state.augroup,
    buffer = state.prompt_buf,
    callback = on_query_change,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = state.augroup,
    callback = function()
      vim.schedule(function()
        local current = vim.api.nvim_get_current_win()
        if
          current ~= state.prompt_win
          and current ~= state.list_win
          and current ~= (state.preview_win or -1)
        then
          M.close()
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = state.augroup,
    buffer = state.list_buf,
    callback = function()
      if state.on_cursor_moved and state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
        state.on_cursor_moved(vim.api.nvim_win_get_cursor(state.list_win)[1])
      end
    end,
  })
end

local function set_prompt_keymaps()
  local opts = { noremap = true, silent = true, buffer = state.prompt_buf }
  vim.keymap.set('i', '<C-n>', function()
    ui.move_cursor(state, 1, update_preview)
  end, opts)
  vim.keymap.set('i', '<Down>', function()
    ui.move_cursor(state, 1, update_preview)
  end, opts)
  vim.keymap.set('i', '<C-p>', function()
    ui.move_cursor(state, -1, update_preview)
  end, opts)
  vim.keymap.set('i', '<Up>', function()
    ui.move_cursor(state, -1, update_preview)
  end, opts)
  vim.keymap.set('i', '<CR>', accept, opts)
  vim.keymap.set('i', '<C-v>', function()
    accept_with_split('vsplit')
  end, opts)
  vim.keymap.set('i', '<C-x>', function()
    accept_with_split('split')
  end, opts)
  vim.keymap.set('i', '<Esc>', function()
    if state.on_esc then
      state.on_esc()
    else
      M.close()
    end
  end, opts)
  vim.keymap.set('i', '<C-c>', M.close, opts)
  vim.keymap.set('n', '<Esc>', M.close, opts)
  vim.keymap.set('n', '<C-c>', M.close, opts)
  vim.keymap.set('i', '<C-b>', '<Left>', opts)
  vim.keymap.set('i', '<C-f>', '<Right>', opts)
  vim.keymap.set('i', '<C-a>', '<Home>', opts)
  vim.keymap.set('i', '<C-e>', '<End>', opts)
  vim.keymap.set('i', '<C-h>', '<BS>', opts)
end

function M.open(source_name, opts)
  opts = opts or {}
  local source = sources[source_name]
  if not source then
    return
  end
  if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
    M.close()
  end

  state.origin_win = vim.api.nvim_get_current_win()
  state.origin_buf = vim.api.nvim_get_current_buf()
  state.on_select = opts.on_select
  state.use_preview = source.use_preview or false
  state.source_opts = {}

  local prompt_buf, prompt_win, list_buf, list_win, preview_buf, preview_win = win.create_windows(
    win.calc_layout(M.config),
    opts.title or source_title(source, source_name),
    state.use_preview,
    source.footer
  )
  state.prompt_buf, state.prompt_win = prompt_buf, prompt_win
  state.list_buf, state.list_win = list_buf, list_win
  state.preview_buf, state.preview_win = preview_buf, preview_win

  vim.fn.prompt_setprompt(prompt_buf, '> ')
  vim.api.nvim_set_current_win(prompt_win)
  vim.cmd('startinsert!')
  set_prompt_keymaps()
  setup_autocmds()
  start_source(source_name, source, opts)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  select.install(M.open)
  vim.keymap.set('n', '<Leader>f', M.files, { desc = 'picker: files' })
  vim.keymap.set('n', '<Leader>b', M.buffers, { desc = 'picker: buffers' })
  vim.keymap.set('n', '<Leader>G', M.grep, { desc = 'picker: grep' })
  vim.keymap.set('n', '<Leader>g', M.git, { desc = 'picker: git' })
  vim.keymap.set('n', '<Leader>l', M.buf_lines, { desc = 'picker: buf_lines' })
  vim.keymap.set('n', '<Leader>e', M.tree, { desc = 'picker: tree' })
end

function M.files()
  M.open('files')
end

function M.buffers()
  M.open('buffers')
end

function M.grep()
  M.open('grep')
end

function M.buf_lines()
  M.open('buf_lines')
end

function M.tree()
  M.open('tree')
end

function M.git()
  M.open('git')
end

function M.ui_select(items, opts, on_choice)
  return select.open(M.open, items, opts, on_choice)
end

return M
