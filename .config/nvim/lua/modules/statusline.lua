local M = {}

-- Mode label map
local mode_map = {
  ['n'] = 'NORMAL',
  ['no'] = 'OP-PEND',
  ['nov'] = 'OP-PEND',
  ['noV'] = 'OP-PEND',
  ['no\22'] = 'OP-PEND',
  ['v'] = 'VISUAL',
  ['vs'] = 'VISUAL',
  ['V'] = 'V-LINE',
  ['Vs'] = 'V-LINE',
  ['\22'] = 'V-BLOCK',
  ['\22s'] = 'V-BLOCK',
  ['s'] = 'SELECT',
  ['S'] = 'S-LINE',
  ['\19'] = 'S-BLOCK',
  ['i'] = 'INSERT',
  ['ic'] = 'INSERT',
  ['ix'] = 'INSERT',
  ['R'] = 'REPLACE',
  ['Rc'] = 'REPLACE',
  ['Rv'] = 'V-REPLACE',
  ['c'] = 'COMMAND',
  ['t'] = 'TERMINAL',
}

local function mode_hlname(m)
  local c = m:sub(1, 1)
  if c == 'i' then
    return 'SLModeInsert'
  elseif c == 'v' or c == 'V' or m == '\22' then
    return 'SLModeVisual'
  elseif c == 'R' then
    return 'SLModeReplace'
  elseif c == 'c' then
    return 'SLModeCommand'
  elseif c == 't' then
    return 'SLModeTerminal'
  else
    return 'SLModeNormal'
  end
end

local function section_mode()
  local m = vim.fn.mode()
  local label = mode_map[m] or m:upper()
  return string.format('%%#%s# %s %%#StatusLine#', mode_hlname(m), label)
end

-- git cache per bufnr:
--   staged    = N  (index に変更あり)
--   unstaged  = N  (worktree に変更あり)
--   untracked = N  (追跡外ファイル数)
--   file_state = 'clean'|'dirty'|'untracked'
local git_cache = {}

local function update_git(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    git_cache[bufnr] = nil
    return
  end
  local dir = vim.fn.fnamemodify(file, ':h')
  -- nvim-pack: や term:// など実在しないパスを持つバッファはスキップ
  if not vim.uv.fs_stat(dir) then
    git_cache[bufnr] = nil
    return
  end
  vim.system(
    { 'git', 'status', '--porcelain=v2', '--branch' },
    { text = true, cwd = dir },
    function(obj)
      vim.schedule(function()
        -- Bail out if the buffer was deleted before the command completed
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        if obj.code ~= 0 or not obj.stdout then
          git_cache[bufnr] = nil
          vim.cmd.redrawstatus()
          return
        end
        local staged, unstaged, untracked = 0, 0, 0
        local file_state = 'clean'
        -- Build an absolute path suffix for exact suffix matching
        local file_tail = '/' .. vim.fn.fnamemodify(file, ':.')
        for line in obj.stdout:gmatch('[^\n]+') do
          if not line:match('^#') then
            local t = line:sub(1, 1)
            if t == '?' then
              -- porcelain v2 untracked: "? <path>"
              untracked = untracked + 1
              local path = line:sub(3)
              if file_tail:sub(- #path - 1) == '/' .. path then
                file_state = 'untracked'
              end
            elseif t == '1' then
              -- porcelain v2 ordinary change: "1 XY <sub> <mH> <mI> <mW> <hH> <hI> <path>"
              local x, y, path = line:match('^1 (.)(.) %S+ %S+ %S+ %S+ %S+ %S+ (.+)$')
              if x then
                if x ~= '.' then staged = staged + 1 end
                if y ~= '.' then unstaged = unstaged + 1 end
                if path and file_tail:sub(- #path - 1) == '/' .. path then
                  file_state = 'dirty'
                end
              end
            elseif t == '2' then
              -- porcelain v2 renamed/copied: "2 XY <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <new>\t<orig>"
              local x, y, paths = line:match('^2 (.)(.) %S+ %S+ %S+ %S+ %S+ %S+ %S+ (.+)$')
              if x then
                if x ~= '.' then staged = staged + 1 end
                if y ~= '.' then unstaged = unstaged + 1 end
                -- paths is "new\torig"; current worktree file is the new name
                local new_path = paths:match('^([^\t]+)')
                if new_path and file_tail:sub(- #new_path - 1) == '/' .. new_path then
                  file_state = 'dirty'
                end
              end
            end
          end
        end
        git_cache[bufnr] = {
          staged     = staged,
          unstaged   = unstaged,
          untracked  = untracked,
          file_state = file_state,
        }
        vim.cmd.redrawstatus()
      end)
    end
  )
end

local function section_git()
  local summary = vim.b.minigit_summary
  if not summary or not summary.head_name or summary.head_name == '' then
    return ''
  end
  local gc = git_cache[vim.api.nvim_get_current_buf()]
  local parts = {}
  if gc then
    if gc.staged > 0 then table.insert(parts, string.format('%%#SLGitStaged#+%d', gc.staged)) end
    if gc.unstaged > 0 then table.insert(parts, string.format('%%#SLGitDirty#~%d', gc.unstaged)) end
    if gc.untracked > 0 then table.insert(parts, string.format('%%#SLGitUntracked#?%d', gc.untracked)) end
  end
  local suffix = #parts > 0 and (' ' .. table.concat(parts, ' ')) or ''
  return string.format('%%#SLGit#  %s%s %%#StatusLine#', summary.head_name, suffix)
end

local file_state_hl = {
  dirty     = 'SLFileDirty',
  untracked = 'SLFileUntracked',
}

local file_state_icon = {
  dirty     = ' %#SLGitDirty#●',
  untracked = ' %#SLGitUntracked#?',
}

local function section_file()
  local name = vim.fn.expand('%:t')
  if name == '' then name = '[No Name]' end
  local modified = vim.bo.modified and ' [+]' or ''
  local readonly = (not vim.bo.modifiable or vim.bo.readonly) and ' [RO]' or ''
  local gc       = git_cache[vim.api.nvim_get_current_buf()]
  local state    = gc and gc.file_state or nil
  local hl       = file_state_hl[state] or 'SLFile'
  local icon     = file_state_icon[state] or ''
  return string.format('%%#%s# %s%s%s%s %%#StatusLine#', hl, name, modified, readonly, icon)
end

local eol_map = { unix = 'LF', dos = 'CRLF', mac = 'CR' }

local function section_encoding()
  local enc = vim.bo.fileencoding ~= '' and vim.bo.fileencoding or vim.o.encoding
  local eol = eol_map[vim.bo.fileformat] or vim.bo.fileformat
  return string.format('%%#SLInfo# %s %s %%#StatusLine#', enc, eol)
end

local diag_hl = {
  [vim.diagnostic.severity.ERROR] = 'SLDiagError',
  [vim.diagnostic.severity.WARN]  = 'SLDiagWarn',
  [vim.diagnostic.severity.HINT]  = 'SLDiagHint',
  [vim.diagnostic.severity.INFO]  = 'SLDiagInfo',
}

local function section_diagnostics()
  local counts = vim.diagnostic.count(0)
  local cfg = vim.diagnostic.config()
  local sign_text = cfg and cfg.signs and cfg.signs.text or {}
  local parts = {}
  for severity, hl in pairs(diag_hl) do
    local n = counts[severity] or 0
    local icon = sign_text[severity]
    if n > 0 and icon then
      table.insert(parts, string.format('%%#%s# %s %d', hl, vim.trim(icon), n))
    end
  end
  if #parts == 0 then return '' end
  return table.concat(parts, '') .. ' %#StatusLine#'
end

local function section_filetype()
  local ft = vim.bo.filetype
  if ft == '' then return '' end
  return string.format('%%#SLInfo# %s %%#StatusLine#', ft)
end

local function section_position()
  return '%#SLInfo# %l:%c %#StatusLine#'
end

local sep = '%#SLSep#\xe2\x94\x82%#StatusLine#'

local function join(parts)
  return table.concat(vim.tbl_filter(function(s) return s ~= '' end, parts), sep)
end

function M.get()
  local left  = join({ section_mode(), section_git(), section_diagnostics(), section_file() })
  local right = join({ section_encoding(), section_filetype(), section_position() })
  return left .. '%=' .. right
end

local function setup_highlights()
  local set_hl = vim.api.nvim_set_hl
  local sl = vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false })
  local bg = sl.bg or 0x21252b

  set_hl(0, 'SLModeNormal', { fg = 0x21252b, bg = 0x61afef, bold = true })
  set_hl(0, 'SLModeInsert', { fg = 0x21252b, bg = 0x98c379, bold = true })
  set_hl(0, 'SLModeVisual', { fg = 0x21252b, bg = 0xe5c07b, bold = true })
  set_hl(0, 'SLModeReplace', { fg = 0x21252b, bg = 0xe06c75, bold = true })
  set_hl(0, 'SLModeCommand', { fg = 0x21252b, bg = 0xc678dd, bold = true })
  set_hl(0, 'SLModeTerminal', { fg = 0x21252b, bg = 0x56b6c2, bold = true })
  set_hl(0, 'SLGit', { fg = 0xabb2bf, bg = bg })
  set_hl(0, 'SLGitStaged', { fg = 0x98c379, bg = bg })
  set_hl(0, 'SLGitDirty', { fg = 0xe5c07b, bg = bg })
  set_hl(0, 'SLGitUntracked', { fg = 0x56b6c2, bg = bg })
  set_hl(0, 'SLFile', { fg = 0xabb2bf, bg = bg, bold = true })
  set_hl(0, 'SLFileDirty', { fg = 0xe5c07b, bg = bg, bold = true })
  set_hl(0, 'SLFileUntracked', { fg = 0x56b6c2, bg = bg, bold = true })
  set_hl(0, 'SLDiagError', { fg = 0xe06c75, bg = bg })
  set_hl(0, 'SLDiagWarn', { fg = 0xe5c07b, bg = bg })
  set_hl(0, 'SLDiagHint', { fg = 0x56b6c2, bg = bg })
  set_hl(0, 'SLDiagInfo', { fg = 0x61afef, bg = bg })
  set_hl(0, 'SLInfo', { fg = 0x5c6370, bg = bg })
  set_hl(0, 'SLSep', { fg = 0x3e4452, bg = bg })
end

function M.setup()
  vim.opt.statusline = '%!v:lua.require("modules/statusline").get()'
  setup_highlights()

  local grp = vim.api.nvim_create_augroup('statusline', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = grp,
    callback = setup_highlights,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'FocusGained' }, {
    group = grp,
    callback = function(ev) update_git(ev.buf) end,
  })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = grp,
    callback = function(ev) git_cache[ev.buf] = nil end,
  })
end

return M
