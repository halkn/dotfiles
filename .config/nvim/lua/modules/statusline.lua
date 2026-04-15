local M = {}

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

local function section(parts)
  return table.concat(vim.tbl_filter(function(x)
    return x and x ~= ''
  end, parts), ' | ')
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

local function diagnostics_summary(bufnr)
  local levels = vim.diagnostic.severity
  local errors = #vim.diagnostic.get(bufnr, { severity = levels.ERROR })
  local warns = #vim.diagnostic.get(bufnr, { severity = levels.WARN })
  local hints = #vim.diagnostic.get(bufnr, { severity = levels.HINT })
  local info = #vim.diagnostic.get(bufnr, { severity = levels.INFO })

  local out = {}
  if errors > 0 then table.insert(out, ('E:%d'):format(errors)) end
  if warns > 0 then table.insert(out, ('W:%d'):format(warns)) end
  if info > 0 then table.insert(out, ('I:%d'):format(info)) end
  if hints > 0 then table.insert(out, ('H:%d'):format(hints)) end
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

function M.render()
  local winid = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local mode = mode_names[vim.fn.mode(1)] or vim.fn.mode(1)
  local filename = buffer_name(bufnr)

  local flags = {}
  if vim.bo[bufnr].modified then table.insert(flags, '[+]') end
  if vim.bo[bufnr].readonly then table.insert(flags, '[RO]') end

  local branch = git_branch(bufnr)
  if branch ~= '' then
    branch = ' ' .. branch
  end

  local left = section({
    mode,
    branch,
    filename,
    table.concat(flags, ''),
    diagnostics_summary(bufnr),
  })

  local right = section({
    progress_summary(),
    vim.bo[bufnr].filetype,
    vim.bo[bufnr].fileencoding ~= '' and vim.bo[bufnr].fileencoding or vim.o.encoding,
    vim.bo[bufnr].fileformat,
    '%p%%',
    '%l:%c',
  })

  return (' %s %%= %s '):format(left, right)
end

function M.setup()
  _G.dotfiles_statusline_render = M.render
  vim.o.laststatus = 3
  vim.o.statusline = '%!v:lua.dotfiles_statusline_render()'

  local group = vim.api.nvim_create_augroup('dotfiles_statusline', { clear = true })
  vim.api.nvim_create_autocmd('DirChanged', {
    group = group,
    callback = function()
      branch_cache = {}
      redraw_statusline()
    end,
  })
end

return M
