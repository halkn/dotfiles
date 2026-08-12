local M = {}

M.config = {
  statusline = "%!v:lua.require'vimrc.statusline'.render()",
}

-- Below this width the statusline drops everything that is available elsewhere.
local narrow_width = 80
local narrow_filename_width = 20
local section_separator = ' | '
local diagnostic_separator = '  '

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

local severity = vim.diagnostic.severity
-- Ordered by severity so the narrow layout can keep the first entry only.
local diagnostic_levels = {
  { key = 'errors', severity = severity.ERROR, hl = 'VimrcStatuslineDiagError', fallback = 'E' },
  { key = 'warns', severity = severity.WARN, hl = 'VimrcStatuslineDiagWarn', fallback = 'W' },
  { key = 'info', severity = severity.INFO, hl = 'VimrcStatuslineDiagInfo', fallback = 'I' },
  { key = 'hints', severity = severity.HINT, hl = 'VimrcStatuslineDiagHint', fallback = 'H' },
}
local diagnostic_icons = {}
local diagnostic_icon_width = 1

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

local function hl(group, text)
  if text == nil or text == '' then
    return ''
  end
  return ('%%#%s#%s%%*'):format(group, text)
end

local function join(parts, separator)
  return table.concat(
    vim.tbl_filter(function(x)
      return x and x ~= ''
    end, parts),
    separator
  )
end

local function section(parts)
  return join(parts, hl('VimrcStatuslineMuted', section_separator))
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
end

local function width(text)
  return vim.fn.strdisplaywidth(text)
end

local function truncate_tail(text, max_width)
  if width(text) <= max_width then
    return text
  end

  local chars = vim.fn.strchars(text)
  local keep = math.max(1, max_width - 1)
  return '…' .. vim.fn.strcharpart(text, chars - keep)
end

-- Signs come from vim.diagnostic.config(), which is set once at startup.
local function resolve_diagnostic_icons()
  local config = vim.diagnostic.config()
  local signs = type(config) == 'table' and config.signs or nil
  local text = type(signs) == 'table' and signs.text or nil

  diagnostic_icon_width = 1
  for _, level in ipairs(diagnostic_levels) do
    local icon = type(text) == 'table' and text[level.severity] or nil
    if type(icon) ~= 'string' or vim.trim(icon) == '' then
      icon = level.fallback
    end
    icon = vim.trim(icon)
    diagnostic_icons[level.severity] = icon
    diagnostic_icon_width = math.max(diagnostic_icon_width, width(icon))
  end
end

local function diagnostic_entry(level, count)
  local icon = diagnostic_icons[level.severity] or level.fallback
  local pad = math.max(1, diagnostic_icon_width - width(icon) + 1)
  return hl(level.hl, ('%s%s%d'):format(icon, string.rep(' ', pad), count))
end

local function diagnostics_counts(bufnr)
  local counts = {}
  for _, level in ipairs(diagnostic_levels) do
    counts[level.key] = #vim.diagnostic.get(bufnr, { severity = level.severity })
  end
  return counts
end

local function diagnostics_summary(counts, compact)
  local entries = {}
  for _, level in ipairs(diagnostic_levels) do
    if counts[level.key] > 0 then
      table.insert(entries, diagnostic_entry(level, counts[level.key]))
      if compact then
        break
      end
    end
  end
  return join(entries, diagnostic_separator)
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

local function file_label(filename, flags, compact)
  if compact then
    filename = truncate_tail(filename, narrow_filename_width)
  end
  if flags == '' then
    return filename
  end
  return ('%s %s'):format(filename, flags)
end

local function redraw_statusline()
  if vim.api.nvim__redraw then
    vim.api.nvim__redraw({ statusline = true })
    return
  end

  vim.cmd.redrawstatus()
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

local function file_encoding(bufnr)
  local encoding = vim.bo[bufnr].fileencoding
  if encoding ~= '' then
    return encoding
  end
  return vim.o.encoding
end

-- laststatus=3 draws a single statusline spanning the whole editor, so the
-- window width would under-report the space available in a split.
local function statusline_width(winid)
  if vim.o.laststatus == 3 then
    return vim.o.columns
  end

  local ok, win_width = pcall(vim.api.nvim_win_get_width, winid)
  if ok and type(win_width) == 'number' and win_width > 0 then
    return win_width
  end
  return vim.o.columns
end

local function mode_label(raw_mode, mode_code)
  local label = mode_names[raw_mode] or mode_names[mode_code] or raw_mode
  return hl(mode_style_names[mode_code] or 'VimrcStatuslineModeOther', label)
end

function M.render()
  local winid = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local raw_mode = vim.fn.mode(1)
  local mode_code = normalize_mode(raw_mode)
  local compact = statusline_width(winid) < narrow_width
  local lsp_clients = lsp_clients_summary(bufnr)

  local left = {
    mode_label(raw_mode, mode_code),
    hl('VimrcStatuslineSection', file_label(buffer_name(bufnr), buffer_flags(bufnr), compact)),
    diagnostics_summary(diagnostics_counts(bufnr), compact),
  }

  -- The right side always renders every item: sections that appear and vanish
  -- with buffer state make the line hard to read at a glance.
  local right = {
    hl('VimrcStatuslineSection', progress_summary()),
    hl('VimrcStatuslineSection', filetype_summary(bufnr, lsp_clients)),
    hl('VimrcStatuslineMuted', file_encoding(bufnr)),
    hl('VimrcStatuslineMuted', vim.bo[bufnr].fileformat),
    hl('VimrcStatuslineMuted', '%p%%'),
    hl('VimrcStatuslineSection', '%l:%c'),
  }

  return (' %s %%= %s '):format(section(left), section(right))
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  setup_highlights()
  resolve_diagnostic_icons()
  vim.o.laststatus = 3
  vim.o.statusline = M.config.statusline

  local group = vim.api.nvim_create_augroup('vimrc_statusline', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'DiagnosticChanged', 'ModeChanged', 'WinEnter' }, {
    group = group,
    callback = redraw_statusline,
  })

  vim.api.nvim_create_autocmd('OptionSet', {
    group = group,
    pattern = { 'modified', 'fileencoding', 'fileformat' },
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
