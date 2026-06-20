local icons = require('vimrc.modules.picker.icons')
local picker_win = require('vimrc.modules.picker.window')

local source = {
  name = 'tree',
  use_preview = true,
}

local tree_state = {
  root = nil,
  open_dirs = {},
  all_files = nil,
  nav_mode = false,
}

local function ensure_children(node)
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

local function flatten()
  local items = {}
  local function walk(node, depth)
    ensure_children(node)
    if not node.children then
      return
    end
    for _, child in ipairs(node.children) do
      local indent = string.rep('  ', depth)
      local display
      if child.is_dir then
        local expanded = tree_state.open_dirs[child.path]
        local dir_icon = expanded and '\xef\x81\xbc' or '\xef\x81\xbb'
        display = indent .. dir_icon .. ' ' .. child.name
      else
        local icon = icons.get_icon(child.name) or ''
        display = indent .. (icon ~= '' and (icon .. ' ') or '  ') .. child.name
      end
      table.insert(items, {
        text = child.path,
        display = display,
        _tree_node = child,
      })
      if child.is_dir and tree_state.open_dirs[child.path] then
        walk(child, depth + 1)
      end
    end
  end
  if tree_state.root then
    walk(tree_state.root, 0)
  end
  return items
end

local function build_filtered(matched_items)
  local root = { children = {} }
  local node_map = { [''] = root }
  local match_pos_map = {}

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
    if item._match_pos then
      match_pos_map[item.text] = item._match_pos
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
        local icon = icons.get_icon(child.name) or ''
        display = indent .. (icon ~= '' and (icon .. ' ') or '  ') .. child.name
      end
      local flat_item = {
        text = child.path,
        display = display,
        _tree_node = child,
      }
      local positions = match_pos_map[child.path]
      if positions and not child.is_dir then
        local name_start = #child.path - #child.name
        local prefix_len = #display - #child.name
        local mapped = {}
        for _, pos in ipairs(positions) do
          if pos >= name_start then
            table.insert(mapped, prefix_len + (pos - name_start))
          end
        end
        if #mapped > 0 then
          flat_item._match_pos = mapped
        end
      end
      table.insert(items, flat_item)
      if child.is_dir then
        walk(child, depth + 1)
      end
    end
  end
  walk(root, 0)
  return items
end

function source.load(config, _, callback)
  local cmd = { 'rg', '--files', '--hidden' }
  for _, glob in ipairs(config.exclude_globs) do
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
      tree_state.all_files = items
    end)
  end)
  return job
end

function source.on_open(ctx)
  tree_state.root = { name = '.', path = '.', is_dir = true, children = nil }
  tree_state.open_dirs = {}
  tree_state.all_files = nil
  tree_state.nav_mode = false
  ensure_children(tree_state.root)
  local items = flatten()
  ctx.set_items(items, items)
  ctx.render()
  ctx.update_cursor()
  ctx.update_preview()

  local function expand(accept_fn)
    local item = ctx.get_current_item()
    if not item or not item._tree_node then
      return
    end
    local node = item._tree_node
    if node.is_dir then
      tree_state.open_dirs[node.path] = true
      ensure_children(node)
      local new_items = flatten()
      ctx.set_items(new_items, new_items)
      ctx.render()
      ctx.update_cursor()
      ctx.update_preview()
    else
      accept_fn()
    end
  end

  local function collapse()
    local item = ctx.get_current_item()
    if not item or not item._tree_node then
      return
    end
    local node = item._tree_node
    if node.is_dir and tree_state.open_dirs[node.path] then
      tree_state.open_dirs[node.path] = nil
      local new_items = flatten()
      ctx.set_items(new_items, new_items)
      ctx.clamp_cursor()
      ctx.render()
      ctx.update_cursor()
      ctx.update_preview()
    else
      local parent_path = vim.fn.fnamemodify(node.path, ':h')
      if parent_path == '.' or parent_path == '' then
        return
      end
      ctx.jump_to_text(parent_path)
    end
  end

  local function enter_nav_mode()
    tree_state.nav_mode = true
    ctx.focus_list()
    picker_win.hide_cursor()
  end

  local function enter_search_mode()
    tree_state.nav_mode = false
    picker_win.restore_cursor()
    ctx.focus_prompt()
  end

  local buf = ctx.list_buf
  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    ctx.move_cursor(1)
  end, opts)
  vim.keymap.set('n', 'k', function()
    ctx.move_cursor(-1)
  end, opts)
  vim.keymap.set('n', 'l', function()
    expand(ctx.accept)
  end, opts)
  vim.keymap.set('n', 'h', function()
    collapse()
  end, opts)
  vim.keymap.set('n', '<CR>', function()
    local item = ctx.get_current_item()
    if item and item._tree_node and item._tree_node.is_dir then
      if tree_state.open_dirs[item._tree_node.path] then
        collapse()
      else
        expand(ctx.accept)
      end
    else
      ctx.accept()
    end
  end, opts)
  vim.keymap.set('n', '/', function()
    enter_search_mode()
  end, opts)
  vim.keymap.set('n', 'i', function()
    enter_search_mode()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    ctx.close()
  end, opts)
  vim.keymap.set('n', 'q', function()
    ctx.close()
  end, opts)
  vim.keymap.set('n', '<C-v>', function()
    ctx.accept_split('vsplit')
  end, opts)
  vim.keymap.set('n', '<C-x>', function()
    ctx.accept_split('split')
  end, opts)
  vim.keymap.set('n', '<C-t>', function()
    ctx.switch_source('files')
  end, opts)

  ctx.set_on_esc(function()
    enter_nav_mode()
  end)

  ctx.set_on_cursor_moved(function(idx)
    if tree_state.nav_mode then
      ctx.set_cursor_idx(idx)
      ctx.update_preview()
    end
  end)

  enter_nav_mode()
end

function source.on_close()
  tree_state.root = nil
  tree_state.open_dirs = {}
  tree_state.all_files = nil
  tree_state.nav_mode = false
end

function source.on_query_change(query, ctx)
  if query == '' then
    local items = flatten()
    ctx.set_items(items, items)
    ctx.set_cursor_idx(1)
  elseif tree_state.all_files then
    local r = vim.fn.matchfuzzypos(tree_state.all_files, query, { key = 'text' })
    local matched, positions = r[1], r[2]
    for i = 1, #matched do
      matched[i]._match_pos = positions[i]
    end
    local items = build_filtered(matched)
    ctx.set_items(items, items)
    ctx.set_cursor_idx(1)
    for i, item in ipairs(items) do
      if not (item._tree_node and item._tree_node.is_dir) then
        ctx.set_cursor_idx(i)
        break
      end
    end
  end
  ctx.render()
  ctx.update_cursor()
  ctx.update_preview()
end

function source.on_accept(item)
  if item._tree_node and item._tree_node.is_dir then
    return
  end
  vim.cmd.edit(item.text)
end

function source.on_accept_split(item, split_cmd)
  if item._tree_node and item._tree_node.is_dir then
    return
  end
  vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
end

function source.update_preview(item, preview_file)
  if item._tree_node and item._tree_node.is_dir then
    return 'clear'
  end
  preview_file(item.text, nil)
end

function source.match_highlight_offset()
  return 0
end

return source
