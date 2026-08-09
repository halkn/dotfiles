local icons = require('vimrc.modules.picker.icons')

local source = {
  name = 'git',
  use_preview = true,
  footer = '<C-i>: toggle scope',
  keymaps = {
    ['<C-i>'] = function(ctx)
      ctx.set_opt('scope', ctx.get_opt('scope') == 'branch' and 'worktree' or 'branch')
      ctx.reload()
    end,
  },
}

function source.title(opts)
  return opts.scope == 'branch' and 'git [branch]' or 'git'
end

-- Keep git's own root-relative path as the match target so the list looks the
-- same from any cwd, and open through the absolute path.
local function make_item(status, path, root)
  local icon = icons.get_icon(path)
  return {
    text = path,
    display = status .. ' ' .. (icon and (icon .. ' ') or '') .. path,
    path = root .. '/' .. path,
  }
end

-- Entries are NUL separated; rename and copy entries carry the original path in
-- the following field.
local function parse_status(stdout, root)
  local items = {}
  local fields = vim.split(stdout, '\0', { plain = true })
  local i = 1
  while i <= #fields do
    local entry = fields[i]
    i = i + 1
    if #entry > 3 then
      local status = entry:sub(1, 2)
      if status:find('[RC]') then
        i = i + 1
      end
      table.insert(items, make_item(status, entry:sub(4), root))
    end
  end
  return items
end

-- `--name-status -z` emits status and path as separate fields; rename and copy
-- statuses are followed by the old path and then the new one.
local function parse_name_status(stdout, root)
  local items = {}
  local fields = vim.split(stdout, '\0', { plain = true })
  local i = 1
  while i + 1 <= #fields do
    local status = fields[i]
    if status == '' then
      break
    end
    local path = fields[i + 1]
    i = i + 2
    if status:find('^[RC]') then
      path = fields[i] or path
      i = i + 1
    end
    table.insert(items, make_item(string.format('%-2s', status:sub(1, 1)), path, root))
  end
  return items
end

local function parse_untracked(stdout, root)
  local items = {}
  for _, path in ipairs(vim.split(stdout, '\0', { plain = true })) do
    if path ~= '' then
      table.insert(items, make_item('??', path, root))
    end
  end
  return items
end

local function git_output(root, args)
  local cmd = { 'git', '-C', root }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout or '') or nil
end

local function resolve_base(root)
  local head = git_output(root, { 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' })
  if head then
    return head
  end
  for _, ref in ipairs({ 'main', 'master', 'origin/main', 'origin/master' }) do
    if git_output(root, { 'rev-parse', '--verify', '--quiet', ref }) then
      return ref
    end
  end
  return nil
end

local function load_worktree(root, callback)
  local cmd = { 'git', '-C', root, 'status', '--porcelain=v1', '-z', '--untracked-files=all' }
  return vim.system(cmd, { text = true }, function(result)
    local stdout = result.code == 0 and result.stdout or nil
    vim.schedule(function()
      callback(stdout and parse_status(stdout, root) or {})
    end)
  end)
end

-- Compare the merge base with the working tree, so the list covers both what is
-- committed on the branch and what is still uncommitted.
local function load_branch(root, callback)
  local base = resolve_base(root)
  if not base then
    vim.schedule(function()
      vim.notify(
        '比較対象のブランチ (main/master) が見つかりません',
        vim.log.levels.WARN
      )
      callback({})
    end)
    return nil
  end
  local diff_cmd = { 'git', '-C', root, 'diff', '--name-status', '-z', '--merge-base', base }
  local untracked_cmd = { 'git', '-C', root, 'ls-files', '--others', '--exclude-standard', '-z' }
  return vim.system(diff_cmd, { text = true }, function(diff)
    vim.system(untracked_cmd, { text = true }, function(untracked)
      local changed = diff.code == 0 and diff.stdout or nil
      local others = untracked.code == 0 and untracked.stdout or nil
      vim.schedule(function()
        local items = changed and parse_name_status(changed, root) or {}
        if others then
          vim.list_extend(items, parse_untracked(others, root))
        end
        table.sort(items, function(a, b)
          return a.text < b.text
        end)
        callback(items)
      end)
    end)
  end)
end

function source.load(_, opts, callback)
  local root = vim.fs.root(vim.uv.cwd(), '.git')
  if not root then
    vim.schedule(function()
      vim.notify('git リポジトリではありません', vim.log.levels.WARN)
      callback({})
    end)
    return nil
  end
  if opts.scope == 'branch' then
    return load_branch(root, callback)
  end
  return load_worktree(root, callback)
end

local function exists(item)
  if vim.uv.fs_stat(item.path) then
    return true
  end
  vim.notify(item.text .. ' は存在しません', vim.log.levels.WARN)
  return false
end

function source.on_accept(item)
  if exists(item) then
    vim.cmd.edit(vim.fn.fnameescape(item.path))
  end
end

function source.on_accept_split(item, split_cmd)
  if exists(item) then
    vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.path))
  end
end

function source.update_preview(item, preview_file)
  if not vim.uv.fs_stat(item.path) then
    return 'clear'
  end
  preview_file(item.path, nil)
end

return source
