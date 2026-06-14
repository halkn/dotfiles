-- explorer.lua: 自前ファイルツリー（Phase 1 MVP）
-- snacks.nvim explorer 風の左サイドバー
-- 対応: ツリー表示 / 開閉 / open(edit/split/vsplit) / 親移動 / refresh / hidden トグル
-- 非対応(Phase 2 以降): 作成・削除・リネーム・移動・コピペ・git status・diagnostics・follow
local M = {}
local hl_ns = vim.api.nvim_create_namespace('vimrc_explorer_hl')

M.config = {
  width = 32,
  show_hidden = false,
}

-- SECTION 1: State -------------------------------------------------------
local state = {
  buf = nil,
  win = nil,
  origin_win = nil,
  root = nil,
  open_dirs = {}, -- path -> true（展開状態を永続保持）
  nodes = {}, -- 描画用に平坦化した node 配列
  show_hidden = false,
}

-- SECTION 2: Icons -------------------------------------------------------
-- picker.lua と同じ解決順（mini.icons → nvim-web-devicons → fallback）
-- 必ずメインスレッドから呼ぶこと
local _icon_fn = nil
local function get_icon(path, is_dir)
  if is_dir then
    return _icon_fn and _icon_fn('dir', path) or ''
  end
  if _icon_fn == false then
    return ''
  end
  if _icon_fn == nil then
    local ok, icons = pcall(require, 'mini.icons')
    if ok and icons.get then
      if not icons.config then
        pcall(icons.setup, {})
      end
      _icon_fn = function(kind, p)
        local cat = kind == 'dir' and 'directory' or 'file'
        local ok2, icon = pcall(icons.get, cat, p)
        if ok2 and icon and icon ~= '' then
          return icon
        end
        return kind == 'dir' and '' or ''
      end
    else
      local ok2, devicons = pcall(require, 'nvim-web-devicons')
      if ok2 then
        _icon_fn = function(kind, p)
          if kind == 'dir' then
            return ''
          end
          local ext = vim.fn.fnamemodify(p, ':e')
          return (devicons.get_icon(p, ext)) or ''
        end
      else
        _icon_fn = false
        return ''
      end
    end
  end
  return _icon_fn('file', path)
end

-- SECTION 3: Tree model --------------------------------------------------
-- 1 階層を読み、directory 優先 → 名前順でソートして返す
local function scan_dir(path)
  local entries = {}
  local fd = vim.uv.fs_scandir(path)
  if not fd then
    return entries
  end
  while true do
    local name, typ = vim.uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if state.show_hidden or name:sub(1, 1) ~= '.' then
      local full = path .. '/' .. name
      -- symlink などは stat で実体種別を確認
      local is_dir = typ == 'directory'
      if typ == 'link' then
        local st = vim.uv.fs_stat(full)
        is_dir = st and st.type == 'directory' or false
      end
      table.insert(entries, {
        name = name,
        path = full,
        type = is_dir and 'directory' or 'file',
      })
    end
  end
  table.sort(entries, function(a, b)
    if a.type ~= b.type then
      return a.type == 'directory'
    end
    return a.name:lower() < b.name:lower()
  end)
  return entries
end

-- open_dirs を辿って再帰展開し、平坦化した node 配列を作る
local function build_tree()
  local nodes = {}
  local function walk(path, depth)
    for _, e in ipairs(scan_dir(path)) do
      local node = {
        name = e.name,
        path = e.path,
        type = e.type,
        depth = depth,
        open = e.type == 'directory' and state.open_dirs[e.path] or false,
      }
      table.insert(nodes, node)
      if node.open then
        walk(e.path, depth + 1)
      end
    end
  end
  walk(state.root, 0)
  state.nodes = nodes
end

-- SECTION 4: Render ------------------------------------------------------
local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  build_tree()

  local lines = {}
  local hls = {} -- { line, col, hl }
  for i, node in ipairs(state.nodes) do
    local indent = string.rep('  ', node.depth)
    local prefix
    if node.type == 'directory' then
      prefix = node.open and '▾ ' or '▸ '
    else
      prefix = '  '
    end
    local icon = get_icon(node.path, node.type == 'directory')
    icon = icon ~= '' and (icon .. ' ') or ''
    local line = indent .. prefix .. icon .. node.name
    lines[i] = line
    if node.type == 'directory' then
      local col = #indent + #prefix
      hls[#hls + 1] = { i - 1, col, 'Directory' }
    end
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(state.buf, hl_ns, 0, -1)
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_set_extmark, state.buf, hl_ns, h[1], h[2], {
      end_row = h[1] + 1,
      hl_group = h[3],
    })
  end

  -- header（ルート名）を winbar に表示
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local label = vim.fn.fnamemodify(state.root, ':~')
    if state.show_hidden then
      label = label .. ' [hidden]'
    end
    vim.wo[state.win].winbar = '%#Title# ' .. label
  end
end

-- SECTION 5: Navigation helpers -----------------------------------------
local function node_under_cursor()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return state.nodes[row]
end

local function focus_origin()
  if state.origin_win and vim.api.nvim_win_is_valid(state.origin_win) then
    vim.api.nvim_set_current_win(state.origin_win)
  else
    -- explorer 以外の通常 window を探す
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= state.win and vim.api.nvim_win_get_config(w).relative == '' then
        vim.api.nvim_set_current_win(w)
        return
      end
    end
    -- 無ければ右に分割を作る
    vim.cmd('rightbelow vsplit')
  end
end

-- SECTION 6: Actions -----------------------------------------------------
local function on_enter()
  local node = node_under_cursor()
  if not node then
    return
  end
  if node.type == 'directory' then
    state.open_dirs[node.path] = not state.open_dirs[node.path] or nil
    render()
  else
    focus_origin()
    vim.cmd.edit(vim.fn.fnameescape(node.path))
  end
end

local function on_split(split_cmd)
  local node = node_under_cursor()
  if not node or node.type ~= 'file' then
    return
  end
  focus_origin()
  vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(node.path))
end

-- 親 dir を閉じる。閉じた dir 自身へカーソルを寄せる
local function collapse_or_parent()
  local node = node_under_cursor()
  if not node then
    return
  end
  if node.type == 'directory' and node.open then
    state.open_dirs[node.path] = nil
    render()
    return
  end
  -- 親ノードを探してそこへ移動
  local parent = vim.fn.fnamemodify(node.path, ':h')
  for i, n in ipairs(state.nodes) do
    if n.path == parent then
      vim.api.nvim_win_set_cursor(state.win, { i, 0 })
      return
    end
  end
end

local function go_up()
  local parent = vim.fn.fnamemodify(state.root, ':h')
  if parent == state.root then
    return
  end
  state.open_dirs[state.root] = true
  state.root = parent
  render()
end

local function refresh()
  render()
end

local function toggle_hidden()
  state.show_hidden = not state.show_hidden
  render()
end

-- SECTION 7: Window ------------------------------------------------------
local function setup_keymaps()
  local opts = { noremap = true, silent = true, buffer = state.buf }
  vim.keymap.set('n', '<CR>', on_enter, opts)
  vim.keymap.set('n', 'l', on_enter, opts)
  vim.keymap.set('n', 'h', collapse_or_parent, opts)
  vim.keymap.set('n', '<C-v>', function()
    on_split('vsplit')
  end, opts)
  vim.keymap.set('n', '<C-x>', function()
    on_split('split')
  end, opts)
  vim.keymap.set('n', '-', go_up, opts)
  vim.keymap.set('n', 'u', go_up, opts)
  vim.keymap.set('n', 'R', refresh, opts)
  vim.keymap.set('n', 'H', toggle_hidden, opts)
  vim.keymap.set('n', 'q', M.close, opts)
  vim.keymap.set('n', '<Esc>', M.close, opts)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function open_win()
  state.origin_win = vim.api.nvim_get_current_win()
  state.root = state.root or vim.uv.cwd()
  state.show_hidden = M.config.show_hidden

  -- 左端・全高の縦分割
  vim.cmd('topleft vsplit')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(state.win, M.config.width)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = 'nofile'
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].filetype = 'explorer'
  vim.api.nvim_win_set_buf(state.win, state.buf)

  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = 'no'
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].winfixwidth = true

  setup_keymaps()

  -- window が閉じられたら state を片付ける
  vim.api.nvim_create_autocmd('WinClosed', {
    buffer = state.buf,
    once = true,
    callback = function()
      state.win = nil
      state.buf = nil
    end,
  })

  render()
end

-- SECTION 8: Public API --------------------------------------------------
function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    open_win()
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  vim.keymap.set('n', '<Leader>e', M.toggle, { desc = 'explorer: toggle' })
end

return M
