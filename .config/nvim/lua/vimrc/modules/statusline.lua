local M = {}

M.config = {
  statusline = "%!v:lua.require'vimrc.modules.statusline'.render()",
}

local mode_style_names = {
  n = 'VimrcStatuslineModeNormal',
  i = 'VimrcStatuslineModeInsert',
  v = 'VimrcStatuslineModeVisual',
  V = 'VimrcStatuslineModeVisual',
  ['\22'] = 'VimrcStatuslineModeVisual',
  c = 'VimrcStatuslineModeCommand',
  r = 'VimrcStatuslineModeReplace',
  R = 'VimrcStatuslineModeReplace',
  t = 'VimrcStatuslineModeTerminal',
}
local compact_width = {
  full = 140,
  medium = 100,
  narrow = 80,
}
local left_part = {
  mode = 1,
  branch = 2,
  file = 3,
  spacer = 4,
  diagnostics = 5,
}
local right_part = {
  progress = 1,
  filetype = 2,
  encoding = 3,
  fileformat = 4,
  percent = 5,
  location = 6,
}
local diagnostic_separator = '  '

local mode_names = {
  n = 'NORMAL',
  no = 'N-PENDING',
  nov = 'N-PENDING',
  noV = 'N-PENDING',
  ['no\22'] = 'N-PENDING',
  niI = 'NORMAL',
  niR = 'NORMAL',
  niV = 'NORMAL',
  nt = 'NORMAL',
  v = 'VISUAL',
  vs = 'VISUAL',
  V = 'V-LINE',
  Vs = 'V-LINE',
  ['\22'] = 'V-BLOCK',
  ['\22s'] = 'V-BLOCK',
  s = 'SELECT',
  S = 'S-LINE',
  ['\19'] = 'S-BLOCK',
  i = 'INSERT',
  ic = 'INSERT',
  ix = 'INSERT',
  R = 'REPLACE',
  Rc = 'REPLACE',
  Rx = 'REPLACE',
  Rv = 'V-REPLACE',
  Rvc = 'V-REPLACE',
  Rvx = 'V-REPLACE',
  c = 'COMMAND',
  cv = 'EX',
  ce = 'EX',
  r = 'PROMPT',
  rm = 'MOAR',
  ['r?'] = 'CONFIRM',
  ['!'] = 'SHELL',
  t = 'TERMINAL',
}

local git_cache = {}
local diagnostic_fallback_icons = {
  ERROR = 'E',
  WARN = 'W',
  INFO = 'I',
  HINT = 'H',
}
local diagnostic_levels = {
  { key = 'errors', severity = vim.diagnostic.severity.ERROR },
  { key = 'warns', severity = vim.diagnostic.severity.WARN },
  { key = 'info', severity = vim.diagnostic.severity.INFO },
  { key = 'hints', severity = vim.diagnostic.severity.HINT },
}

local function normalize_mode(mode)
  local c = mode:sub(1, 1)
  if c == '\22' then
    return '\22'
  end
  if c == 'n' then
    return 'n'
  end
  if c == 'i' then
    return 'i'
  end
  if c == 'v' or c == 'V' then
    return c
  end
  if c == 'c' then
    return 'c'
  end
  if c == 'r' or c == 'R' then
    return c
  end
  if c == 't' then
    return 't'
  end
  return mode
end

local function section(parts)
  return table.concat(
    vim.tbl_filter(function(x)
      return x and x ~= ''
    end, parts),
    ' | '
  )
end

local function hl(group, text)
  if text == nil or text == '' then
    return ''
  end
  return ('%%#%s#%s%%*'):format(group, text)
end

local function set_hl_from(group, source, opts)
  local ok, base = pcall(vim.api.nvim_get_hl, 0, { name = source, link = false })
  if not ok or type(base) ~= 'table' then
    base = {}
  end
  local spec = vim.tbl_extend('force', base, opts or {})
  vim.api.nvim_set_hl(0, group, spec)
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'VimrcStatuslineSection', { link = 'StatusLine' })
  vim.api.nvim_set_hl(0, 'VimrcStatuslineMuted', { link = 'StatusLineNC' })
  vim.api.nvim_set_hl(0, 'VimrcStatuslineModeOther', { link = 'Title' })
  set_hl_from('VimrcStatuslineModeNormal', 'DiagnosticOk', { bold = true })
  set_hl_from('VimrcStatuslineModeInsert', 'DiagnosticInfo', { bold = true })
  set_hl_from('VimrcStatuslineModeVisual', 'DiagnosticHint', { bold = true })
  set_hl_from('VimrcStatuslineModeCommand', 'DiagnosticWarn', { bold = true })
  set_hl_from('VimrcStatuslineModeReplace', 'DiagnosticError', { bold = true })
  set_hl_from('VimrcStatuslineModeTerminal', 'Special', { bold = true })
  set_hl_from('VimrcStatuslineDiagError', 'DiagnosticError', { bold = true })
  set_hl_from('VimrcStatuslineDiagWarn', 'DiagnosticWarn', { bold = true })
  set_hl_from('VimrcStatuslineDiagInfo', 'DiagnosticInfo', { bold = true })
  set_hl_from('VimrcStatuslineDiagHint', 'DiagnosticHint', { bold = true })
  set_hl_from('VimrcStatuslineGitAhead', 'DiagnosticInfo', { bold = true })
  set_hl_from('VimrcStatuslineGitBehind', 'DiagnosticWarn', { bold = true })
  set_hl_from('VimrcStatuslineGitDirty', 'DiffChange', { bold = true })
  set_hl_from('VimrcStatuslineGitUntracked', 'DiffAdd', { bold = true })
end

local function width(text)
  return vim.fn.strdisplaywidth(text)
end

local function truncate_tail(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local chars = vim.fn.strchars(text)
  local keep = math.max(1, max_width - 1)
  return '…' .. vim.fn.strcharpart(text, chars - keep)
end

local function buffer_name(bufnr)
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype
  local raw_name = vim.api.nvim_buf_get_name(bufnr)

  if bt == '' then
    local filename = vim.fn.fnamemodify(raw_name, ':t')
    return filename ~= '' and filename or '[No Name]'
  end

  local kind = bt ~= '' and bt or (ft ~= '' and ft or 'buffer')
  if raw_name == '' then
    return ('[%s]'):format(kind)
  end

  local short = vim.fn.fnamemodify(raw_name, ':t')
  if bt == 'terminal' then
    short = raw_name:match('term://[^:]+:%d+:(.+)$') or short
  end
  if short == '' then
    short = raw_name
  end

  return ('[%s] %s'):format(kind, truncate_tail(short, 28))
end

local function redraw_statusline()
  if vim.api.nvim__redraw then
    vim.api.nvim__redraw({ statusline = true })
    return
  end

  vim.cmd.redrawstatus()
end

local function diagnostic_icon(severity)
  local config = vim.diagnostic.config()
  local signs = type(config) == 'table' and config.signs or nil
  local text = type(signs) == 'table' and signs.text or nil
  local icon = type(text) == 'table' and text[severity] or nil
  if type(icon) ~= 'string' or icon == '' then
    local level = vim.diagnostic.severity
    local fallback = {
      [level.ERROR] = diagnostic_fallback_icons.ERROR,
      [level.WARN] = diagnostic_fallback_icons.WARN,
      [level.INFO] = diagnostic_fallback_icons.INFO,
      [level.HINT] = diagnostic_fallback_icons.HINT,
    }
    icon = fallback[severity] or 'D'
  end
  return vim.trim(icon)
end

local function diagnostic_statusline_icon(severity)
  return diagnostic_icon(severity)
end

local function max_diagnostic_icon_width()
  local level = vim.diagnostic.severity
  return math.max(
    vim.fn.strdisplaywidth(diagnostic_statusline_icon(level.ERROR)),
    vim.fn.strdisplaywidth(diagnostic_statusline_icon(level.WARN)),
    vim.fn.strdisplaywidth(diagnostic_statusline_icon(level.INFO)),
    vim.fn.strdisplaywidth(diagnostic_statusline_icon(level.HINT))
  )
end

local function format_diagnostic_count(severity, count)
  local icon = diagnostic_statusline_icon(severity)
  local pad = math.max(1, max_diagnostic_icon_width() - vim.fn.strdisplaywidth(icon) + 1)
  return ('%s%s%d'):format(icon, string.rep(' ', pad), count)
end

local function format_diagnostic_entries(counts)
  local out = {}
  for _, entry in ipairs(diagnostic_levels) do
    local count = counts[entry.key]
    if count > 0 then
      table.insert(out, format_diagnostic_count(entry.severity, count))
    end
  end
  return out
end

local function diagnostics_counts(bufnr)
  local counts = {}
  for _, entry in ipairs(diagnostic_levels) do
    counts[entry.key] = #vim.diagnostic.get(bufnr, { severity = entry.severity })
  end
  return counts
end

local function diagnostics_summary(counts)
  return table.concat(format_diagnostic_entries(counts), diagnostic_separator)
end

local function find_git_root(path)
  if path == '' then
    return nil
  end

  if vim.fs.root then
    return vim.fs.root(path, '.git')
  end

  local git_dir = vim.fs.find('.git', {
    upward = true,
    path = path,
    stop = vim.uv.os_homedir(),
  })[1]

  if not git_dir then
    return nil
  end

  return vim.fn.fnamemodify(git_dir, ':h')
end

local function git_root(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local base = file ~= '' and vim.fn.fnamemodify(file, ':p:h') or vim.uv.cwd()
  return find_git_root(base)
end

local function git_info(bufnr)
  local root = git_root(bufnr)
  if not root then
    return { head = '', status = '' }
  end

  if git_cache[root] then
    return git_cache[root]
  end

  local lines = vim.fn.systemlist({ 'git', '-C', root, 'status', '--porcelain=2', '--branch' })
  if vim.v.shell_error ~= 0 then
    git_cache[root] = { head = '', status = '' }
    return git_cache[root]
  end

  local head = ''
  local oid = ''
  local ahead = 0
  local behind = 0
  local changed = 0
  local untracked = 0

  for _, line in ipairs(lines) do
    if vim.startswith(line, '# branch.head ') then
      head = line:sub(15)
    elseif vim.startswith(line, '# branch.oid ') then
      oid = line:sub(14)
    elseif vim.startswith(line, '# branch.ab ') then
      local ahead_str, behind_str = line:match('%+(%d+) %-(%d+)')
      ahead = tonumber(ahead_str) or 0
      behind = tonumber(behind_str) or 0
    elseif vim.startswith(line, '? ') then
      untracked = untracked + 1
    elseif
      vim.startswith(line, '1 ')
      or vim.startswith(line, '2 ')
      or vim.startswith(line, 'u ')
    then
      changed = changed + 1
    end
  end

  local parts = {}
  if ahead > 0 then
    table.insert(parts, ('↑%d'):format(ahead))
  end
  if behind > 0 then
    table.insert(parts, ('↓%d'):format(behind))
  end
  if changed > 0 then
    table.insert(parts, ('*%d'):format(changed))
  end
  if untracked > 0 then
    table.insert(parts, ('?%d'):format(untracked))
  end

  if head == '(detached)' and oid ~= '' then
    head = oid:sub(1, 7)
  end

  git_cache[root] = {
    head = head,
    status = table.concat(parts, ' '),
  }

  return git_cache[root]
end

local function progress_summary()
  local pieces = {}
  if type(vim.ui.progress_status) == 'function' then
    local status = vim.ui.progress_status()
    if status ~= '' then
      table.insert(pieces, status)
    end
  end

  local ok, lsp_status = pcall(vim.lsp.status)
  if ok and lsp_status ~= '' then
    table.insert(pieces, lsp_status)
  end

  return table.concat(pieces, ' ')
end

local function lsp_clients_summary(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return ''
  end

  local names = {}
  local seen = {}
  for _, client in ipairs(clients) do
    if type(client.name) == 'string' and client.name ~= '' and not seen[client.name] then
      seen[client.name] = true
      table.insert(names, client.name)
    end
  end

  table.sort(names)
  return table.concat(names, ',')
end

local function filetype_summary(bufnr, lsp_clients)
  local filetype = vim.bo[bufnr].filetype
  if filetype == '' then
    filetype = 'noft'
  end
  if lsp_clients == '' then
    return filetype
  end
  return ('%s[%s]'):format(filetype, lsp_clients)
end

local function buffer_flags(bufnr)
  local flags = {}
  if vim.bo[bufnr].modified then
    table.insert(flags, '[+]')
  end
  if vim.bo[bufnr].readonly then
    table.insert(flags, '[RO]')
  end
  return table.concat(flags, '')
end

local function file_encoding(bufnr)
  local encoding = vim.bo[bufnr].fileencoding
  if encoding ~= '' then
    return encoding
  end
  return vim.o.encoding
end

local function window_width(winid)
  local ok, win_width = pcall(vim.api.nvim_win_get_width, winid)
  if ok and type(win_width) == 'number' and win_width > 0 then
    return win_width
  end
  return vim.o.columns
end

local function build_context()
  local winid = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local raw_mode = vim.fn.mode(1)
  local mode_code = normalize_mode(raw_mode)
  local git = git_info(bufnr)
  local branch = git.head
  local diagnostics = diagnostics_counts(bufnr)
  local lsp_clients = lsp_clients_summary(bufnr)
  if branch ~= '' then
    branch = ' ' .. branch
  end

  return {
    winid = winid,
    bufnr = bufnr,
    width = window_width(winid),
    mode = mode_names[raw_mode] or mode_names[mode_code] or raw_mode,
    mode_code = mode_code,
    branch = branch,
    git = git.status,
    filename = buffer_name(bufnr),
    flags = buffer_flags(bufnr),
    diagnostics = diagnostics_summary(diagnostics),
    diagnostic_counts = diagnostics,
    lsp_clients = lsp_clients,
    progress = progress_summary(),
    filetype = filetype_summary(bufnr, lsp_clients),
    encoding = file_encoding(bufnr),
    fileformat = vim.bo[bufnr].fileformat,
    percent = '%p%%',
    location = '%l:%c',
  }
end

local function branch_label(branch, git)
  if branch == '' then
    return ''
  end
  if git == '' then
    return branch
  end
  return ('%s (%s)'):format(branch, git)
end

local function file_label(filename, flags)
  if flags == '' then
    return filename
  end
  return ('%s %s'):format(filename, flags)
end

local function build_left(ctx)
  return {
    ctx.mode,
    branch_label(ctx.branch, ctx.git),
    file_label(ctx.filename, ctx.flags),
    '',
    ctx.diagnostics,
  }
end

local function build_right(ctx)
  return {
    ctx.progress,
    ctx.filetype,
    ctx.encoding,
    ctx.fileformat,
    ctx.percent,
    ctx.location,
  }
end

local function compact_filename(ctx, max_width)
  if width(ctx.filename) <= max_width then
    return
  end
  ctx.filename = truncate_tail(ctx.filename, max_width)
end

local function compact_diagnostics(counts)
  local total = counts.errors + counts.warns + counts.info + counts.hints
  if total == 0 then
    return ''
  end

  if counts.errors > 0 then
    return format_diagnostic_count(vim.diagnostic.severity.ERROR, counts.errors)
  end
  if counts.warns > 0 then
    return format_diagnostic_count(vim.diagnostic.severity.WARN, counts.warns)
  end
  return format_diagnostic_count(vim.diagnostic.severity.INFO, total)
end

local function compact_git_status(text)
  if text == '' then
    return ''
  end

  local parts = vim.split(text, ' ', { trimempty = true })
  return parts[1] or ''
end

local function style_mode(ctx)
  local mode = ctx.mode_code
  local group = mode_style_names[mode]
  if group then
    return hl(group, ctx.mode)
  end
  return hl('VimrcStatuslineModeOther', ctx.mode)
end

local function style_diagnostics(text)
  if text == '' then
    return ''
  end

  local levels = vim.diagnostic.severity
  local groups = {
    [diagnostic_statusline_icon(levels.ERROR)] = 'VimrcStatuslineDiagError',
    [diagnostic_statusline_icon(levels.WARN)] = 'VimrcStatuslineDiagWarn',
    [diagnostic_statusline_icon(levels.INFO)] = 'VimrcStatuslineDiagInfo',
    [diagnostic_statusline_icon(levels.HINT)] = 'VimrcStatuslineDiagHint',
    [diagnostic_fallback_icons.ERROR] = 'VimrcStatuslineDiagError',
    [diagnostic_fallback_icons.WARN] = 'VimrcStatuslineDiagWarn',
    [diagnostic_fallback_icons.INFO] = 'VimrcStatuslineDiagInfo',
    [diagnostic_fallback_icons.HINT] = 'VimrcStatuslineDiagHint',
  }
  local styled = {}
  for _, part in ipairs(vim.split(text, diagnostic_separator, { trimempty = true, plain = true })) do
    local icon = vim.trim((part:match('^([^%d]+)') or ''))
    local group = groups[icon] or 'VimrcStatuslineSection'
    table.insert(styled, hl(group, part))
  end
  return table.concat(styled, diagnostic_separator)
end

local function style_git_status(text)
  if text == '' then
    return ''
  end

  local styled = {}
  for _, part in ipairs(vim.split(text, ' ', { trimempty = true })) do
    local prefix = part:sub(1, 1)
    local group = ({
      ['↑'] = 'VimrcStatuslineGitAhead',
      ['↓'] = 'VimrcStatuslineGitBehind',
      ['*'] = 'VimrcStatuslineGitDirty',
      ['?'] = 'VimrcStatuslineGitUntracked',
    })[prefix] or 'VimrcStatuslineSection'
    table.insert(styled, hl(group, part))
  end
  return table.concat(styled, ' ')
end

local function style_branch(ctx)
  if ctx.branch == '' then
    return ''
  end

  if ctx.git == '' then
    return hl('VimrcStatuslineSection', ctx.branch)
  end

  return table.concat({
    hl('VimrcStatuslineSection', ctx.branch),
    hl('VimrcStatuslineMuted', '('),
    style_git_status(ctx.git),
    hl('VimrcStatuslineMuted', ')'),
  }, '')
end

local function style_parts(left, right, ctx)
  left[left_part.mode] = style_mode(ctx)
  left[left_part.branch] = style_branch(ctx)
  left[left_part.file] = hl('VimrcStatuslineSection', left[left_part.file])
  left[left_part.spacer] = hl('VimrcStatuslineMuted', left[left_part.spacer])
  left[left_part.diagnostics] = style_diagnostics(left[left_part.diagnostics])

  right[right_part.progress] = hl('VimrcStatuslineSection', right[right_part.progress])
  right[right_part.filetype] = hl('VimrcStatuslineSection', right[right_part.filetype])
  right[right_part.encoding] = hl('VimrcStatuslineMuted', right[right_part.encoding])
  right[right_part.fileformat] = hl('VimrcStatuslineMuted', right[right_part.fileformat])
  right[right_part.percent] = hl('VimrcStatuslineMuted', right[right_part.percent])
  right[right_part.location] = hl('VimrcStatuslineSection', right[right_part.location])
  return left, right
end

local function compact_parts(left, right, ctx)
  if ctx.width >= compact_width.full then
    return left, right
  end

  right[right_part.encoding] = ''
  right[right_part.fileformat] = ''
  if ctx.width >= compact_width.medium then
    return left, right
  end

  ctx.git = compact_git_status(ctx.git)
  left[left_part.branch] = branch_label(ctx.branch, ctx.git)
  left[left_part.diagnostics] = compact_diagnostics(ctx.diagnostic_counts)
  compact_filename(ctx, 32)
  left[left_part.file] = file_label(ctx.filename, ctx.flags)
  if ctx.width >= compact_width.narrow then
    return left, right
  end

  left[left_part.branch] = ''
  ctx.branch = ''
  ctx.git = ''
  left[left_part.diagnostics] = ''
  right[right_part.progress] = ''
  compact_filename(ctx, 20)
  left[left_part.file] = file_label(ctx.filename, ctx.flags)
  return left, right
end

local function join_statusline(left, right)
  return (' %s %%= %s '):format(section(left), section(right))
end

function M.render()
  local ctx = build_context()
  local left = build_left(ctx)
  local right = build_right(ctx)
  left, right = compact_parts(left, right, ctx)
  left, right = style_parts(left, right, ctx)
  return join_statusline(left, right)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  setup_highlights()
  vim.o.laststatus = 3
  vim.o.statusline = M.config.statusline

  local group = vim.api.nvim_create_augroup('vimrc_statusline', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'DirChanged', 'DiagnosticChanged' }, {
    group = group,
    callback = function()
      git_cache = {}
      redraw_statusline()
    end,
  })

  local redraw_events = { 'ModeChanged', 'WinEnter', 'BufModifiedSet' }
  vim.api.nvim_create_autocmd(redraw_events, {
    group = group,
    callback = redraw_statusline,
  })

  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach', 'LspProgress' }, {
    group = group,
    callback = redraw_statusline,
  })

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      setup_highlights()
      redraw_statusline()
    end,
  })
end

return M
