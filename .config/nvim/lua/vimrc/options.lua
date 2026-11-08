local g = vim.g
local opt = vim.opt

-- Don't use Japanese in neovim
vim.env.LANG = 'C.UTF-8'
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

opt.fileencodings = 'utf-8,sjis,iso-2022-jp,cp932,euc-jp'

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
-- Matches the headless default, but the TUI asks the terminal and would follow its background.
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
opt.switchbuf = 'useopen'

opt.undofile = true
opt.swapfile = false

opt.diffopt:append('vertical')

-- edit
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.virtualedit = 'block,onemore'
opt.whichwrap = 'b,s,[,],<,>'

-- window
opt.splitbelow = true
opt.splitright = true
opt.laststatus = 3
opt.cmdheight = 0
-- The default 'cmd' target keeps messages in a cmdline that is hidden at
-- cmdheight=0; 'msg' shows them in a window that outlives the startup redraws.
require('vim._core.ui2').enable({ msg = { targets = 'msg' } })
opt.pumheight = 10
opt.previewheight = 10
opt.winwidth = 30
opt.winborder = 'rounded'
opt.cmdwinheight = 5
opt.equalalways = false

-- search and replace
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = 'split'

opt.wildoptions = 'pum'
opt.pumblend = 10
opt.pumborder = 'rounded'

-- completion: buffer words as you type, until an LSP server with completion
-- attaches and vim.lsp.completion takes over (lua/vimrc/lsp.lua).
opt.autocomplete = true
opt.complete = '.,w'
-- Without "menuone" a single match shows no menu, and <Tab> (lua/vimrc/keymaps.lua)
-- cannot accept it. "noselect" keeps an LSP answer, which opens the menu by its
-- own complete() call, from inserting its first item.
opt.completeopt = 'menu,menuone,noselect,popup,fuzzy'
-- "match 1 of N" would pop up as a message on every <Tab> accept.
opt.shortmess:append('c')

opt.clipboard = 'unnamedplus'
opt.updatetime = 250

if vim.fn.executable('rg') == 1 then
  opt.grepprg = 'rg --vimgrep --hidden --glob "!**/.git/*"'
  opt.grepformat = '%f:%l:%c:%m'
end

-- lsp/gopls.lua only attaches under the 'gotmpl' filetype.
vim.filetype.add({
  extension = {
    gotmpl = 'gotmpl',
    gohtml = 'gotmpl',
  },
})
