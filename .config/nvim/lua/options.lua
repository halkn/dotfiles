local g = vim.g
local opt = vim.opt

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
opt.encoding = "utf-8"
opt.fileencodings = "utf-8,sjis,iso-2022-jp,cp932,euc-jp"
opt.fileencoding = "utf-8"

-- Appearance
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.wrap = false
opt.list = true
opt.listchars = "tab:»-,extends:»,precedes:«,nbsp:%,eol:↲,trail:~"
opt.scrolloff= 8
opt.termguicolors = true
opt.background = "dark"
opt.synmaxcol = 512
opt.foldenable = false
opt.fillchars = {
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vert = "┃",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
}

-- buffer
opt.hidden = true
opt.switchbuf = "useopen"

-- backupfile
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- diff
opt.diffopt = opt.diffopt + "vertical,indent-heuristic"

-- edit
opt.smarttab = true
opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.virtualedit = "block,onemore"
opt.whichwrap = "b,s,[,],<,>"

-- window
opt.splitbelow = true
opt.splitright = true
opt.cmdheight = 1
opt.pumheight = 10
opt.previewheight = 10
opt.winwidth = 30
opt.cmdwinheight = 5
opt.equalalways = false

-- search and replace
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = "split"

-- pum
opt.wildoptions = "pum"
opt.pumblend = 10

-- other
opt.clipboard = "unnamedplus"
opt.lazyredraw = true

-- grep
-- `rg`コマンドの存在を確認し、存在する場合に`grepprg`と`grepformat`を設定
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep"
  opt.grepformat = "%f:%l:%c:%m"
end
