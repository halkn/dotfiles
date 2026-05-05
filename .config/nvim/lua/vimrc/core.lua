local g = vim.g
local opt = vim.opt

-- Don't use Japanese in neovim
if vim.fn.has('unix') == 1 then
  vim.env.LANG = 'C.UTF-8'
else
  vim.env.LANG = 'en'
end
vim.cmd.language(vim.env.LANG)
vim.o.langmenu = vim.env.LANG

-- disable built-in plugin and remote provider
g.loaded_python3_provider = 0
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_gzip = 1
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.loaded_matchparen = 1
g.loaded_tar = 1
g.loaded_tarPlugin = 1
g.loaded_zip = 1
g.loaded_zipPlugin = 1

-- encoding
opt.fileencodings = 'utf-8,sjis,iso-2022-jp,cp932,euc-jp'
opt.fileencoding = 'utf-8'

-- Appearance
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.wrap = false
opt.showmode = false
opt.list = true
opt.listchars = 'tab:»-,extends:»,precedes:«,nbsp:%,eol:↲,trail:~'
opt.scrolloff = 8
opt.termguicolors = true
opt.background = 'dark'
opt.synmaxcol = 512
opt.foldenable = false
opt.fillchars = {
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┫',
  vertright = '┣',
  verthoriz = '╋',
}

-- buffer
opt.hidden = true
opt.switchbuf = 'useopen'

-- backupfile
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- diff
opt.diffopt = opt.diffopt + 'vertical,linematch:40,indent-heuristic,inline:char'

-- edit
opt.smarttab = true
opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.virtualedit = 'block,onemore'
opt.whichwrap = 'b,s,[,],<,>'

-- window
opt.splitbelow = true
opt.splitright = true
opt.laststatus = 3
opt.cmdheight = 0
opt.pumheight = 10
opt.previewheight = 10
opt.winwidth = 30
opt.winborder = 'rounded'
opt.cmdwinheight = 5
opt.equalalways = false

-- search and replace
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = 'split'

-- pum
opt.wildoptions = 'pum'
opt.pumblend = 10
opt.pumborder = 'rounded'

-- other
opt.clipboard = 'unnamedplus'
opt.updatetime = 250

-- grep
if vim.fn.executable('rg') == 1 then
  opt.grepprg = 'rg --vimgrep --hidden --glob "!**/.git/*"'
  opt.grepformat = '%f:%l:%c:%m'
end

-- diagnostic
vim.diagnostic.config({
  virtual_text = {
    current_line = true,
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    },
  },
})

vim.g.mapleader = [[ ]]
vim.g.maplocalleader = [[,]]

local map = function(mode, lhs, rhs)
  local opts = { silent = false, noremap = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

local remap = function(mode, lhs, rhs)
  local opts = { silent = false, remap = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Improve Multi Line Move
map('n', 'k', 'gk')
map('n', 'j', 'gj')
map('n', 'gj', 'j')
map('n', 'gk', 'k')

-- Improve Cursor Move in Normal,Visial-Mode
map({ 'n', 'v' }, 'H', '^')
map({ 'n', 'v' }, 'L', '$')

-- Improve Cursor Move in Insert-Mode (emacs like)
map('i', '<C-b>', '<Left>')
map('i', '<C-f>', '<Right>')
map('i', '<C-a>', '<C-o>^')
map('i', '<C-e>', '<End>')
map('i', '<C-d>', '<Del>')

-- Improve Cursor Move in Cmdline-Mode (emacs like)
map('c', '<C-b>', '<Left>')
map('c', '<C-f>', '<Right>')
map('c', '<C-a>', '<HOME>')
map('c', '<C-e>', '<END>')

-- Improve Operation for Window
map('n', '<Tab>', '<C-w>w')
map('n', '<S-Tab>', '<C-w>W')
map('n', '<Left>', '5<C-w><')
map('n', '<Right>', '5<C-w>>')
map('n', '<Up>', '2<C-w>+')
map('n', '<Down>', '2<C-w>-')
map('n', '<C-q>', '<cmd>q<CR>')
map('i', '<C-q>', '<cmd>q<CR><Esc>')
map('t', '<C-q>', '<cmd>q!<CR>')

-- Improve Yank for delete operation
map({ 'n', 'x' }, 'x', '"_x')
map({ 'n', 'x' }, 'X', '"_X')

-- Does not move when using *
map('n', '*', '*N')

-- Indent in visual and select mode automatically re-selects.
map('v', '>', '>gv')
map('v', '<', '<gv')

-- Disable dangerous key
map('n', 'ZZ', '<Nop>')
map('n', 'ZQ', '<Nop>')

-- Clear search highlight
map('n', '<Esc><Esc>', '<cmd>nohlsearch<CR><Esc>')
map('n', '<C-l>', '<cmd>nohlsearch<CR><C-l>')

-- Toggle options
map('n', '<Leader>on', '<cmd>setlocal number! number?<CR>')
map('n', '<Leader>or', '<cmd>setlocal relativenumber! relativenumber?<CR>')
map('n', '<Leader>oc', '<cmd>setlocal cursorline! cursorcolumn!<CR>')
map('n', '<Leader>ow', '<cmd>setlocal wrap! wrap?<CR>')

-- Improve Terminal-Mode
map('t', '<Esc>', '<C-\\><C-n>')
map('t', '<C-y>', '<C-\\><C-n>')
map('n', '<Leader>ts', '<cmd>horizontal terminal<CR>')
map('n', '<Leader>tv', '<cmd>vertical terminal<CR>')
map('n', '<Leader>tt', '<cmd>tab terminal<CR>')
map('n', '<Leader>tw', '<cmd>terminal<CR>')

-- quickfix/loclist
map('n', '[q', '<cmd>cprev<CR>')
map('n', ']q', '<cmd>cnext<CR>')
map('n', '[l', '<cmd>lprevious<CR>')
map('n', ']l', '<cmd>lnext<CR>')

-- commenting
remap({ 'n', 'x', 'o' }, '<Leader>c', 'gcc')
remap('v', '<Leader>c', 'gc')

-- diagnostic
map('n', '<C-e>', vim.diagnostic.open_float)
map('n', '<Leader>d', vim.diagnostic.setqflist)

local autocmd = vim.api.nvim_create_autocmd

local group_name = 'vimrc_config'
vim.api.nvim_create_augroup(group_name, { clear = true })

-- Quickfix
autocmd('QuickFixCmdPost', {
  group = group_name,
  pattern = { 'make', 'grep', 'grepadd', 'vimgrep', 'vimgrepadd' },
  callback = function()
    vim.cmd.cwin()
  end,
})

autocmd('FileType', {
  group = group_name,
  pattern = { 'qf' },
  callback = function()
    local opts = { silent = false, noremap = true, buffer = true }
    vim.keymap.set('n', 'q', '<cmd>cclose<cr>', opts)
  end,
})

-- help
autocmd('FileType', {
  group = group_name,
  pattern = { 'help' },
  callback = function()
    local opts = { silent = false, noremap = true, buffer = true }
    vim.keymap.set('n', '<CR>', '<C-]>', opts)
    vim.keymap.set('n', '<BS>', '<C-T>', opts)
    vim.keymap.set('n', 'q', '<cmd>q<cr>', opts)
    vim.cmd('wincmd L')
  end,
})

-- terminal
autocmd('TermOpen', {
  group = group_name,
  callback = function()
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = 'no'
    vim.cmd.startinsert()
  end,
})

-- git
autocmd('FileType', {
  group = group_name,
  pattern = { 'gitcommit' },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = 'cjk,en'
  end,
})

-- Briefly highlight yanked text
autocmd('TextYankPost', {
  group = group_name,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})
