local M = {}

local priority = { [' '] = 0, ['?'] = 1, A = 2, C = 3, M = 4, T = 5, R = 6, D = 7, U = 8 }
local conflicts = { DD = true, AU = true, UD = true, UA = true, DU = true, AA = true, UU = true }
local symbols = {
  A = { '✚', 'Added' },
  M = { '●', 'DiagnosticWarn' },
  T = { '●', 'DiagnosticWarn' },
  D = { '✖', 'Removed' },
  R = { '➜', 'Special' },
  C = { '', 'Special' },
  U = { '!', 'DiagnosticError' },
  ['?'] = { '?', 'NonText' },
}

---@param status string
---@return table[]
function M.chunks(status)
  if status == '!!' then
    return { { '  ' }, { '◌', 'NonText' } }
  end
  local index = status:sub(1, 1)
  local staged = symbols[index]
  return {
    staged and { staged[1], index == 'U' and 'DiagnosticError' or 'DiagnosticHint' } or { ' ' },
    { ' ' },
    symbols[status:sub(2, 2)] or { ' ' },
  }
end

---@param statuses table<string, string?>
---@param path string
---@return string?
function M.status(statuses, path)
  if statuses[path] then
    return statuses[path]
  end
  local parent = vim.fs.dirname(path)
  while parent do
    if statuses[parent] == '!!' then
      return '!!'
    end
    local next_parent = vim.fs.dirname(parent)
    if next_parent == parent then
      break
    end
    parent = next_parent
  end
end

---@param root string
---@param output string
---@return table<string, string>
function M.parse(root, output)
  local statuses = {}
  local function aggregate(path, status)
    while path do
      local previous = statuses[path] or '  '
      local merged = ''
      for col = 1, 2 do
        local old, new = previous:sub(col, col), status:sub(col, col)
        merged = merged .. ((priority[new] or 0) > (priority[old] or 0) and new or old)
      end
      statuses[path] = merged
      if path == root then
        break
      end
      local parent = vim.fs.dirname(path)
      if parent == path then
        break
      end
      path = parent
    end
  end
  local records = vim.split(output, '\0', { plain = true })
  local i = 1
  while i <= #records do
    local record = assert(records[i])
    local xy, name = record:sub(1, 2), record:sub(4)
    if #record >= 4 and record:sub(3, 3) == ' ' and xy == '!!' then
      statuses[vim.fs.joinpath(root, (name:gsub('/$', '')))] = '!!'
    elseif #record >= 4 and record:sub(3, 3) == ' ' then
      local status = conflicts[xy] and 'UU' or xy == '??' and ' ?' or xy
      aggregate(vim.fs.joinpath(root, (name:gsub('/$', ''))), status)
      if xy:find('[RC]') then
        -- Porcelain -z emits the destination first, then the unprefixed original path.
        i = i + 1
        local original = records[i]
        if original and original ~= '' and xy:find('R', 1, true) then
          aggregate(vim.fs.dirname(vim.fs.joinpath(root, original)), status)
        end
      end
    end
    i = i + 1
  end
  return statuses
end

---@param cwd string
---@param callback fun(statuses: table<string, string>, err?: string)
---@return fun()
function M.fetch(cwd, callback)
  local cancelled = false
  ---@type vim.SystemObj?
  local job
  local function run(args, done)
    local ok, result = pcall(vim.system, args, { cwd = cwd, timeout = 5000 }, function(res)
      vim.schedule(function()
        if not cancelled then
          job = nil
          done(res)
        end
      end)
    end)
    if ok then
      job = result
    else
      vim.schedule(function()
        if not cancelled then
          callback({}, tostring(result))
        end
      end)
    end
  end
  if vim.fn.executable('git') == 1 then
    run({ 'git', 'rev-parse', '--show-toplevel' }, function(result)
      if result.code ~= 0 then
        callback({})
        return
      end
      local root = (result.stdout or ''):gsub('\n$', '')
      run({
        'git',
        '--no-optional-locks',
        'status',
        '--porcelain=v1',
        '-z',
        '--untracked-files=all',
        '--ignored=matching',
        '--renames',
      }, function(status)
        if status.code ~= 0 then
          callback({}, status.stderr ~= '' and status.stderr or 'git status failed')
          return
        end
        callback(M.parse(root, status.stdout or ''))
      end)
    end)
  else
    vim.schedule(function()
      if not cancelled then
        callback({})
      end
    end)
  end
  return function()
    cancelled = true
    if job then
      job:kill(15)
      job = nil
    end
  end
end

return M
