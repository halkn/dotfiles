local M = {}

M.setup = function()
  -- VS Code latest default dark (2026-dark) inspired palette.
  local p = {
    bg = '#0d1117',
    bg_alt = '#161b22',
    bg_popup = '#161b22',
    bg_visual = '#264f78',
    bg_cursorline = '#1f2630',
    fg = '#bbbebf',
    fg_muted = '#8b949e',
    fg_subtle = '#6e7681',
    border = '#30363d',
    keyword = '#c586c0',
    type = '#569cd6',
    string = '#a5d6ff',
    variable = '#c9d1d9',
    function_name = '#d2a8ff',
    number = '#79c0ff',
    comment = '#8b949e',
    error = '#f85149',
    warn = '#d29922',
    info = '#58a6ff',
    hint = '#3fb950',
  }

  vim.o.background = 'dark'
  vim.g.colors_name = 'vscode_2026_dark'

  local set = vim.api.nvim_set_hl

  set(0, 'Normal', { fg = p.fg, bg = p.bg })
  set(0, 'NormalFloat', { fg = p.fg, bg = p.bg_popup })
  set(0, 'FloatBorder', { fg = p.border, bg = p.bg_popup })
  set(0, 'CursorLine', { bg = p.bg_cursorline })
  set(0, 'CursorLineNr', { fg = p.fg, bold = true })
  set(0, 'LineNr', { fg = p.fg_subtle })
  set(0, 'SignColumn', { bg = p.bg })
  set(0, 'ColorColumn', { bg = p.bg_alt })
  set(0, 'Visual', { bg = p.bg_visual })
  set(0, 'Search', { fg = p.bg, bg = '#ffd33d' })
  set(0, 'IncSearch', { fg = p.bg, bg = '#ffa657' })
  set(0, 'Pmenu', { fg = p.fg, bg = p.bg_popup })
  set(0, 'PmenuSel', { fg = p.fg, bg = p.bg_visual })
  set(0, 'StatusLine', { fg = p.fg, bg = p.bg_alt })
  set(0, 'StatusLineNC', { fg = p.fg_muted, bg = p.bg_alt })
  set(0, 'WinSeparator', { fg = p.border })

  set(0, 'Comment', { fg = p.comment, italic = true })
  set(0, 'Constant', { fg = p.number })
  set(0, 'String', { fg = p.string })
  set(0, 'Character', { fg = p.string })
  set(0, 'Number', { fg = p.number })
  set(0, 'Boolean', { fg = p.number })
  set(0, 'Identifier', { fg = p.variable })
  set(0, 'Function', { fg = p.function_name })
  set(0, 'Statement', { fg = p.keyword })
  set(0, 'Keyword', { fg = p.keyword })
  set(0, 'Type', { fg = p.type })
  set(0, 'PreProc', { fg = p.keyword })
  set(0, 'Special', { fg = '#ffa657' })

  set(0, 'DiagnosticError', { fg = p.error })
  set(0, 'DiagnosticWarn', { fg = p.warn })
  set(0, 'DiagnosticInfo', { fg = p.info })
  set(0, 'DiagnosticHint', { fg = p.hint })

  set(0, '@comment', { link = 'Comment' })
  set(0, '@keyword', { link = 'Keyword' })
  set(0, '@string', { link = 'String' })
  set(0, '@function', { link = 'Function' })
  set(0, '@type', { link = 'Type' })
end

return M
