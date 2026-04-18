local M = {}
local mode_style_names = {
  n = 'DotfilesStatuslineModeNormal',
  i = 'DotfilesStatuslineModeInsert',
  v = 'DotfilesStatuslineModeVisual',
  V = 'DotfilesStatuslineModeVisual',
  ['\22'] = 'DotfilesStatuslineModeVisual',
  c = 'DotfilesStatuslineModeCommand',
  r = 'DotfilesStatuslineModeReplace',
  R = 'DotfilesStatuslineModeReplace',
  t = 'DotfilesStatuslineModeTerminal',
}
local compact_width = {
  full = 140,
  medium = 100,
  narrow = 80,
}

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

local branch_cache = {}

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
  return table.concat(vim.tbl_filter(function(x)
    return x and x ~= ''
  end, parts), ' | ')
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
  vim.api.nvim_set_hl(0, 'DotfilesStatuslineSection', { link = 'StatusLine' })
  vim.api.nvim_set_hl(0, 'DotfilesStatuslineMuted', { link = 'StatusLineNC' })
  vim.api.nvim_set_hl(0, 'DotfilesStatuslineModeOther', { link = 'Title' })
  set_hl_from('DotfilesStatuslineModeNormal', 'DiagnosticOk', { bold = true })
  set_hl_from('DotfilesStatuslineModeInsert', 'DiagnosticInfo', { bold = true })
  set_hl_from('DotfilesStatuslineModeVisual', 'DiagnosticHint', { bold = true })
  set_hl_from('DotfilesStatuslineModeCommand', 'DiagnosticWarn', { bold = true })
  set_hl_from('DotfilesStatuslineModeReplace', 'DiagnosticError', { bold = true })
  set_hl_from('DotfilesStatuslineModeTerminal', 'Special', { bold = true })
  set_hl_from('DotfilesStatuslineDiagError', 'DiagnosticError', { bold = true })
  set_hl_from('DotfilesStatuslineDiagWarn', 'DiagnosticWarn', { bold = true })
  set_hl_from('DotfilesStatuslineDiagInfo', 'DiagnosticInfo', { bold = true })
  set_hl_from('DotfilesStatuslineDiagHint', 'DiagnosticHint', { bold = true })
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
    local filename = vim.fn.fnamemodify(raw_name, ':~:.')
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

local function diagnostics_counts(bufnr)
  local levels = vim.diagnostic.severity
  return {
    errors = #vim.diagnostic.get(bufnr, { severity = levels.ERROR }),
    warns = #vim.diagnostic.get(bufnr, { severity = levels.WARN }),
    info = #vim.diagnostic.get(bufnr, { severity = levels.INFO }),
    hints = #vim.diagnostic.get(bufnr, { severity = levels.HINT }),
  }
end

local function diagnostics_summary(bufnr, counts)
  local diag_status = vim.diagnostic.status
  if type(diag_status) == 'function' then
    local ok, status = pcall(diag_status, { bufnr = bufnr })
    if not ok then
      ok, status = pcall(diag_status, bufnr)
    end
    if not ok then
      ok, status = pcall(diag_status)
    end
    if ok and type(status) == 'string' and status ~= '' then
      return status
    end
  end

  local out = {}
  if counts.errors > 0 then table.insert(out, ('E:%d'):format(counts.errors)) end
  if counts.warns > 0 then table.insert(out, ('W:%d'):format(counts.warns)) end
  if counts.info > 0 then table.insert(out, ('I:%d'):format(counts.info)) end
  if counts.hints > 0 then table.insert(out, ('H:%d'):format(counts.hints)) end
  return table.concat(out, ' ')
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

local function git_branch(bufnr)
  if type(vim.b[bufnr].gitsigns_head) == 'string' and vim.b[bufnr].gitsigns_head ~= '' then
    return vim.b[bufnr].gitsigns_head
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  local base = file ~= '' and vim.fn.fnamemodify(file, ':p:h') or vim.uv.cwd()
  local root = find_git_root(base)
  if not root then
    return ''
  end

  if branch_cache[root] then
    return branch_cache[root]
  end

  local name = vim.fn.systemlist({ 'git', '-C', root, 'branch', '--show-current' })[1] or ''
  if vim.v.shell_error ~= 0 then
    branch_cache[root] = ''
    return ''
  end

  branch_cache[root] = name
  return name
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
  local branch = git_branch(bufnr)
  local diagnostics = diagnostics_counts(bufnr)
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
    filename = buffer_name(bufnr),
    flags = buffer_flags(bufnr),
    diagnostics = diagnostics_summary(bufnr, diagnostics),
    diagnostic_counts = diagnostics,
    progress = progress_summary(),
    filetype = vim.bo[bufnr].filetype,
    encoding = file_encoding(bufnr),
    fileformat = vim.bo[bufnr].fileformat,
    percent = '%p%%',
    location = '%l:%c',
  }
end

local function build_left(ctx)
  return {
    ctx.mode,
    ctx.branch,
    ctx.filename,
    ctx.flags,
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
    return ('E:%d'):format(counts.errors)
  end
  if counts.warns > 0 then
    return ('W:%d'):format(counts.warns)
  end
  return ('D:%d'):format(total)
end

local function style_mode(ctx)
  local mode = ctx.mode_code
  local group = mode_style_names[mode]
  if group then
    return hl(group, ctx.mode)
  end
  return hl('DotfilesStatuslineModeOther', ctx.mode)
end

local function style_diagnostics(text)
  if text == '' then
    return ''
  end

  local styled = {}
  for _, part in ipairs(vim.split(text, ' ', { trimempty = true })) do
    local prefix = part:sub(1, 1)
    local group = ({
      E = 'DotfilesStatuslineDiagError',
      W = 'DotfilesStatuslineDiagWarn',
      I = 'DotfilesStatuslineDiagInfo',
      H = 'DotfilesStatuslineDiagHint',
      D = 'DotfilesStatuslineDiagInfo',
    })[prefix] or 'DotfilesStatuslineSection'
    table.insert(styled, hl(group, part))
  end
  return table.concat(styled, ' ')
end

local function style_parts(left, right, ctx)
  left[1] = style_mode(ctx)
  left[2] = hl('DotfilesStatuslineSection', left[2])
  left[3] = hl('DotfilesStatuslineSection', left[3])
  left[4] = hl('DotfilesStatuslineMuted', left[4])
  left[5] = style_diagnostics(left[5])

  right[1] = hl('DotfilesStatuslineMuted', right[1])
  right[2] = hl('DotfilesStatuslineSection', right[2])
  right[3] = hl('DotfilesStatuslineMuted', right[3])
  right[4] = hl('DotfilesStatuslineMuted', right[4])
  right[5] = hl('DotfilesStatuslineMuted', right[5])
  right[6] = hl('DotfilesStatuslineSection', right[6])
  return left, right
end

local function compact_parts(left, right, ctx)
  if ctx.width >= compact_width.full then
    return left, right
  end

  right[3] = ''
  right[4] = ''
  if ctx.width >= compact_width.medium then
    return left, right
  end

  right[1] = ''
  left[5] = compact_diagnostics(ctx.diagnostic_counts)
  compact_filename(ctx, 32)
  left[3] = ctx.filename
  if ctx.width >= compact_width.narrow then
    return left, right
  end

  left[2] = ''
  left[5] = ''
  compact_filename(ctx, 20)
  left[3] = ctx.filename
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

function M.setup()
  setup_highlights()
  _G.dotfiles_statusline_render = M.render
  vim.o.laststatus = 3
  vim.o.statusline = '%!v:lua.dotfiles_statusline_render()'

  local group = vim.api.nvim_create_augroup('dotfiles_statusline', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'DirChanged', 'DiagnosticChanged' }, {
    group = group,
    callback = function()
      branch_cache = {}
      redraw_statusline()
    end,
  })

  vim.api.nvim_create_autocmd({ 'ModeChanged', 'WinEnter', 'BufModifiedSet' }, {
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

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitSignsUpdate',
    callback = function()
      branch_cache = {}
      redraw_statusline()
    end,
  })
end

return M
