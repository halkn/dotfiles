local icons = require('vimrc.modules.picker.icons')

local source = {
  name = 'git',
  use_preview = true,
}

-- Entries are NUL separated; rename and copy entries carry the original path in
-- the following field. Paths are always relative to the repository root.
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
      -- Keep git's own root-relative path as the match target so the list looks
      -- the same from any cwd, and open through the absolute path.
      local path = entry:sub(4)
      local icon = icons.get_icon(path)
      table.insert(items, {
        text = path,
        display = status .. ' ' .. (icon and (icon .. ' ') or '') .. path,
        path = root .. '/' .. path,
      })
    end
  end
  return items
end

local function exists(item)
  if vim.uv.fs_stat(item.path) then
    return true
  end
  vim.notify(item.text .. ' は存在しません', vim.log.levels.WARN)
  return false
end

function source.load(_, _, callback)
  local root = vim.fs.root(vim.uv.cwd(), '.git')
  if not root then
    vim.schedule(function()
      vim.notify('git リポジトリではありません', vim.log.levels.WARN)
      callback({})
    end)
    return nil
  end
  local cmd = { 'git', '-C', root, 'status', '--porcelain=v1', '-z', '--untracked-files=all' }
  local job = vim.system(cmd, { text = true }, function(result)
    local stdout = result.code == 0 and result.stdout or nil
    vim.schedule(function()
      callback(stdout and parse_status(stdout, root) or {})
    end)
  end)
  return job
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
