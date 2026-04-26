local tools = require('tools')

local M = {}

local function run(argv, opts)
  opts = opts or {}
  local result = vim.system(argv, { text = true, cwd = opts.cwd }):wait()
  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    local stdout = vim.trim(result.stdout or '')
    local detail = stderr ~= '' and stderr or stdout
    error(('%s failed%s'):format(table.concat(argv, ' '), detail ~= '' and (': ' .. detail) or ''))
  end

  return result
end

local function ensure_command(name)
  if vim.fn.executable(name) ~= 1 then
    error(('required command not found: %s'):format(name))
  end
end

local function ensure_dir(path)
  vim.fn.mkdir(path, 'p')
end

local function remove_path(path)
  if vim.uv.fs_stat(path) ~= nil then
    vim.fn.delete(path, 'rf')
  end
end

local function latest_release(tool)
  local url = ('https://api.github.com/repos/%s/releases/latest'):format(tool.repo)
  local result = run({ 'curl', '-fsSL', url })
  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if not ok or type(decoded) ~= 'table' then
    error(('failed to decode latest release response for %s'):format(tool.name))
  end

  return decoded
end

local function find_asset(tool, release)
  for _, asset in ipairs(release.assets or {}) do
    if type(asset.name) == 'string' and asset.name:match(tool.asset_pattern) then
      return asset
    end
  end

  error(('release asset not found for %s: %s'):format(tool.name, tool.asset_pattern))
end

local function download_asset(url, archive_path)
  run({ 'curl', '-fL', '--retry', '3', '-o', archive_path, url })
end

local function extract_archive(archive_path, extract_dir)
  ensure_dir(extract_dir)

  if archive_path:match('%.zip$') then
    ensure_command('unzip')
    run({ 'unzip', '-oq', archive_path, '-d', extract_dir })
    return
  end

  if archive_path:match('%.tar%.gz$') or archive_path:match('%.tgz$') then
    ensure_command('tar')
    run({ 'tar', '-xzf', archive_path, '-C', extract_dir })
    return
  end

  error(('unsupported archive format: %s'):format(archive_path))
end

local function link_executable(tool, opt_dir)
  local source = vim.fs.joinpath(opt_dir, tool.executable_path)
  if vim.uv.fs_stat(source) == nil then
    error(('executable not found after install: %s'):format(source))
  end

  local target = tools.resolve(tool.name)
  ensure_dir(tools.bin_dir())
  remove_path(target)
  run({ 'ln', '-s', source, target })
end

local function install_tool(tool, opts)
  opts = opts or {}
  ensure_command('curl')

  if not opts.force and tools.is_installed(tool.name) then
    return { name = tool.name, skipped = true, path = tools.resolve(tool.name) }
  end

  local package_dir = tools.package_dir(tool.name)
  local extract_dir = vim.fs.joinpath(package_dir, 'extract')
  local archive_path = vim.fs.joinpath(package_dir, 'archive')
  local opt_dir = tools.opt_dir(tool.name)

  remove_path(package_dir)
  ensure_dir(package_dir)

  local release = latest_release(tool)
  local asset = find_asset(tool, release)
  archive_path = archive_path .. asset.name:match('(%.[^.]+)$')
  if asset.name:match('%.tar%.gz$') then
    archive_path = vim.fs.joinpath(package_dir, 'archive.tar.gz')
  elseif asset.name:match('%.zip$') then
    archive_path = vim.fs.joinpath(package_dir, 'archive.zip')
  end

  download_asset(asset.browser_download_url, archive_path)
  extract_archive(archive_path, extract_dir)

  remove_path(opt_dir)
  ensure_dir(opt_dir)
  run({ 'cp', '-a', extract_dir .. '/.', opt_dir })
  run({ 'chmod', '-R', 'u+rwX', opt_dir })
  run({ 'chmod', 'u+x', vim.fs.joinpath(opt_dir, tool.executable_path) })
  link_executable(tool, opt_dir)

  return {
    name = tool.name,
    version = release.tag_name,
    asset = asset.name,
    path = tools.resolve(tool.name),
  }
end

local function selected_tools(name)
  if name and name ~= '' then
    local tool = tools.registry[name]
    if tool == nil then
      error(('unknown managed tool: %s'):format(name))
    end
    return { tool }
  end

  local selected = {}
  for tool_name in pairs(tools.default_tools()) do
    local tool = tools.registry[tool_name]
    if tool ~= nil then
      table.insert(selected, tool)
    end
  end

  table.sort(selected, function(a, b)
    return a.name < b.name
  end)

  return selected
end

function M.install(name)
  local installed = {}
  for _, tool in ipairs(selected_tools(name)) do
    table.insert(installed, install_tool(tool, { force = false }))
  end
  return installed
end

function M.update(name)
  local installed = {}
  for _, tool in ipairs(selected_tools(name)) do
    table.insert(installed, install_tool(tool, { force = true }))
  end
  return installed
end

return M
