-- ===========================================================================
-- Global variables
-- ===========================================================================
-- Disable default plugin
vim.g.loaded_gzip               = 1
vim.g.loaded_tar                = 1
vim.g.loaded_tarPlugin          = 1
vim.g.loaded_zip                = 1
vim.g.loaded_zipPlugin          = 1
vim.g.loaded_rrhelper           = 1
vim.g.loaded_vimball            = 1
vim.g.loaded_vimballPlugin      = 1
vim.g.loaded_getscript          = 1
vim.g.loaded_getscriptPlugin    = 1
vim.g.loaded_netrw              = 1
vim.g.loaded_netrwPlugin        = 1
vim.g.loaded_netrwSettings      = 1
vim.g.loaded_netrwFileHandlers  = 1
vim.g.did_install_default_menus = 1
vim.g.skip_loading_mswin        = 1
vim.g.did_install_syntax_menu   = 1
vim.g.loaded_2html_plugin       = 1

-- map leader
vim.cmd [[let g:mapleader = "\<Space>"]]
vim.g.maplocalleader = ','

-- indent for Line continuation.(\)
vim.g.vim_indent_cont = 0

-- markdown syntax
vim.g.markdown_fenced_languages = {
  'go',
  'sh',
  'json',
  'yaml',
  'lua',
  'vim',
}

-- use lua syntax in .vim file
vim.g.vimsyn_embed = 'l'

-- ===========================================================================
-- Global options
-- ===========================================================================
-- Encoding
vim.o.encoding = 'utf-8'
vim.o.fileencodings = 'utf-8,cp932'
vim.o.fileformats = 'unix,dos,mac'

-- Persistence files
vim.o.backup = false
vim.o.swapfile = false
vim.o.undofile = false
vim.o.undodir = vim.fn.stdpath('cache') .. '/.undodir'
vim.o.undofile = true

-- Display
vim.o.display = 'lastline'
vim.wo.cursorcolumn = false
vim.wo.cursorline = false
vim.wo.wrap = false
vim.wo.list = true
vim.o.listchars = 'tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%'
vim.wo.scrolloff = 8
vim.o.synmaxcol = 256
vim.o.showtabline = 2
vim.wo.signcolumn = 'yes'
vim.o.background = 'dark'
vim.o.virtualedit = 'block,onemore'
vim.o.termguicolors = true
vim.o.pumblend = 10

-- lastline
vim.o.laststatus = 2
vim.o.showmode = false
vim.o.showcmd = true
vim.o.shortmess = vim.o.shortmess .. 'c'

-- buffer
vim.o.hidden = true
vim.o.switchbuf = 'useopen'

-- insertmode
vim.o.smarttab = true
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.shiftwidth = 4
vim.o.shiftround = true
vim.o.tabstop = 4
vim.o.whichwrap = 'b,s,[,],<,>'
vim.o.backspace = 'indent,eol,start'
vim.o.completeopt = 'menu,menuone,noselect'

-- window
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.winwidth = 30
vim.o.winheight = 1
vim.o.equalalways = false

-- search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.inccommand = 'split'

-- cmdline
vim.o.wildmenu = true

-- cmdwin
vim.o.cmdwinheight = 5

-- clipborad
vim.o.clipboard = 'unnamedplus'

-- grep
if vim.fn.executable('rg') then
  vim.o.grepprg = 'rg --vimgrep --hidden'
  vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- ===========================================================================
-- Mappings
-- ===========================================================================
-- utilty function
local mapper_c = function (mode, key, result)
  vim.api.nvim_set_keymap(mode, key, result, {})
end
local map  = function (key, result) mapper_c('',  key, result) end
local nmap = function (key, result) mapper_c('n', key, result) end
local vmap = function (key, result) mapper_c('v', key, result) end
local omap = function (key, result) mapper_c('o', key, result) end
local xmap = function (key, result) mapper_c('x', key, result) end

local noremapper = function (mode, key, result)
  local opts
  if mode == 'c' then
    opts = {noremap=true}
  else
    opts = {silent=true, noremap=true}
  end
  vim.api.nvim_set_keymap(mode, key, result, opts)
end
local nnoremap = function(key, result) noremapper('n', key, result) end
local inoremap = function(key, result) noremapper('i', key, result) end
local vnoremap = function(key, result) noremapper('v', key, result) end
local tnoremap = function(key, result) noremapper('t', key, result) end
local cnoremap = function(key, result) noremapper('c', key, result) end

-- reload init.lua
nnoremap('<Leader>s', '<cmd>luafile ~/.config/nvim/init.lua<CR>')

-- clear search highlight
nnoremap('<Esc><Esc>', '<cmd>nohlsearch<CR>')

-- Multi line move
nnoremap('k', 'gk')
nnoremap('j', 'gj')
nnoremap('gk', 'k')
nnoremap('gj', 'j')
nnoremap('<Down>', 'gj')
nnoremap('<Up>', 'gk')

-- Move cursor like emacs in Insert Mode
inoremap('<C-b>', '<Left>')
inoremap('<C-f>', '<Right>')
inoremap('<C-a>', '<C-o>^')
inoremap('<C-e>', '<End>')
inoremap('<C-d>', '<Del>')

-- Move cursor like emacs in Cmdline-mode
cnoremap('<C-b>', '<Left>')
cnoremap('<C-f>', '<Right>')
cnoremap('<C-a>', '<HOME>')
cnoremap('<C-e>', '<END>')

-- forward match from cmdline history
cnoremap('<C-p>', '<Up>')
cnoremap('<C-n>', '<Down>')

-- Move cursor the begining and end of line
nnoremap('H', '^')
nnoremap('L', '$')
vnoremap('H', '^')
vnoremap('L', '$')

-- Move between windows
nnoremap('<Tab>', '<c-w>w')
nnoremap('<S-Tab>', '<c-w>W')

-- Not yank is delete operation
nnoremap('x', '"_x')
nnoremap('X', '"_X')
vnoremap('x', '"_x')
vnoremap('X', '"_X')

-- Indent in visual and select mode automatically re-selects.
vnoremap('>', '>gv')
vnoremap('<', '<gv')

-- Quit the current window
nnoremap('<C-q>', '<cmd>q<CR>')
inoremap('<C-q>', '<cmd>q<CR>')
tnoremap('<C-q>', '<cmd>q<CR>')

-- open termianl in vertial split,new tab,current winddow
nnoremap('<Leader>ts', '<cmd>split term://$SHELL<CR>')
nnoremap('<Leader>tv', '<cmd>vsplit term://$SHELL<CR>')
nnoremap('<Leader>tt', '<cmd>tabnew term://$SHELL<CR>')
nnoremap('<Leader>tw', '<cmd>terminal<CR>')

-- ESC in terminal-mode
tnoremap('<Esc>', '<C-\\><C-n>')

-- Toggle some options
nnoremap('[Toggle]', '<Nop>')
map('<Leader>o', '[Toggle]')
nnoremap('[Toggle]n', '<cmd>setlocal number! number?<CR>')
nnoremap('[Toggle]rn', '<cmd>setlocal relativenumber! relativenumber?<CR>')
nnoremap('[Toggle]c', '<cmd>setlocal cursorline! cursorcolumn!<CR>')
nnoremap('[Toggle]w', '<cmd>setlocal wrap! wrap?<CR>')
nnoremap('[Toggle]p', '<cmd>setlocal paste! paste!<CR>')

-- quickfix
nnoremap('[q', '<cmd>cprev<CR>')
nnoremap(']q', '<cmd>cnext<CR>')
nnoremap('[l', '<cmd>lprev<CR>')
nnoremap(']l', '<cmd>lnext<CR>')
function _G.toggleqf(mode)
  local ocmd, ccmd
  if mode == 'q' then
    ocmd = 'cwindow'
    ccmd = 'cclose'
  elseif mode == 'l' then
    ocmd = 'lwindow'
    ccmd = 'lclose'
  end
  local nr = vim.fn.winnr('$')
  vim.api.nvim_command(ocmd)
  local nr2 = vim.fn.winnr('$')
  if nr == nr2 then
    vim.api.nvim_command(ccmd)
  end
end
nnoremap('Q', '<cmd>call v:lua.toggleqf("q")<CR>')
nnoremap('W', '<cmd>call v:lua.toggleqf("l")<CR>')

-- ===========================================================================
-- autocmd
-- ===========================================================================
local create_augroups = function(definitions)
  local api = vim.api
  for group_name, definition in pairs(definitions) do
    api.nvim_command('augroup '..group_name)
    api.nvim_command('autocmd!')
    for _, def in ipairs(definition) do
      local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
      api.nvim_command(command)
    end
    api.nvim_command('augroup END')
  end
end

function _G.qfenter(wcmd)
  local lnum = vim.fn.line('.')
  local cmd, ccmd
  if vim.fn.get(vim.fn.get(vim.fn.getwininfo(vim.fn.win_getid()), 0, {}), 'loclist', 0) == 1 then
    cmd = 'll'
    ccmd = 'lclose'
  else
    cmd = 'cc'
    ccmd = 'cclose'
  end
  vim.api.nvim_command(wcmd)
  vim.api.nvim_command(cmd .. lnum)
  vim.api.nvim_command(ccmd)
end

function _G.helpvert()
  if vim.bo.buftype == 'help' then
    vim.api.nvim_command('wincmd L')
  end
end

create_augroups({
  vimrc_ft = {
    {"FileType", "gitcommit", "setlocal spell spelllang=cjk,en"};
    {"FileType", "git", "setlocal nofoldenable"};
    {"FileType", "go", "setlocal noexpandtab tabstop=4 shiftwidth=4"};
    {"FileType", "vim", "setlocal tabstop=2 shiftwidth=2"};
    {"FileType", "lua", "setlocal tabstop=2 shiftwidth=2"};
    {"FileType", "sh", "setlocal tabstop=2 shiftwidth=2"};
    {"FileType", "zsh", "setlocal tabstop=2 shiftwidth=2"};
    {"FileType", "yaml", "setlocal tabstop=2 shiftwidth=2"};
    {"FileType", "json", "setlocal tabstop=2 shiftwidth=2"};
  };
  vimrc_qf = {
    {"FileType", "qf", "setlocal signcolumn=no"};
    {"FileType", "qf", "nnoremap <silent> <buffer> p <CR>zz<C-w>p"};
    {"FileType", "qf", "nnoremap <silent> <buffer> q <C-w>c"};
    {"FileType", "qf", "nnoremap <silent> <buffer> <C-m> <cmd>call v:lua.qfenter('wincmd p')<CR>"};
    {"FileType", "qf", "nnoremap <silent> <buffer> <C-t> <cmd>call v:lua.qfenter('tabnew')<CR>"};
    {"FileType", "qf", "nnoremap <silent> <buffer> <C-x> <cmd>call v:lua.qfenter('wincmd p <bar> new')<CR>"};
    {"FileType", "qf", "nnoremap <silent> <buffer> <C-v> <cmd>call v:lua.qfenter('wincmd p <bar> vnew')<CR>"};
  };
  vimrc_help = {
    {"BufEnter", "*.txt", "call v:lua.helpvert()"};
    {"FileType", "help", "setlocal signcolumn=no"};
    {"FileType", "help", "nnoremap <silent> <buffer> q <C-w>c"};
    {"FileType", "help", "nnoremap <buffer> <CR> <C-]>"};
    {"FileType", "help", "nnoremap <buffer> <BS> <C-T>"};
  };
  vimrc_termoepn = {
    {"TermOpen", "*", "setlocal signcolumn=no nolist"};
    {"TermOpen", "*", "startinsert"};
  };
  vimrc_yank = {
    {"TextYankPost", "*", "silent! lua return (not vim.v.event.visual) and require'vim.highlight'.on_yank()"};
  };
})

-- ===========================================================================
-- abbrev
-- ===========================================================================
-- Shortening for ++enc=
vim.cmd [[
cnoreabbrev ++u ++enc=utf8
cnoreabbrev ++c ++enc=cp932
cnoreabbrev ++s ++enc=sjis
]]

-- ===========================================================================
-- Plugins
-- ===========================================================================
local packadd = function(paq) vim.cmd('packadd '..paq) end

-- package manager - paq
packadd('paq-nvim')
local paq = require'paq-nvim'.paq
paq{'savq/paq-nvim', opt=true}

-- appearance
paq'glepnir/zephyr-nvim'
paq'ChristianChiarulli/nvcode-color-schemes.vim'
paq'nvim-treesitter/nvim-treesitter'
paq'hoob3rt/lualine.nvim'

-- enhanced
paq 'hrsh7th/vim-eft'
paq 'tyru/columnskip.vim'
paq 'cohama/lexima.vim'
paq 'machakann/vim-sandwich'
paq 'kana/vim-operator-user'
paq 'kana/vim-operator-replace'
paq 'mattn/vim-findroot'

-- fuzzyfinder
paq 'junegunn/fzf'
paq 'junegunn/fzf.vim'
paq 'ojroques/nvim-lspfuzzy'

-- extension
paq 'nvim-lua/plenary.nvim'
paq 'lewis6991/gitsigns.nvim'
paq 'glidenote/memolist.vim'
paq 'skywind3000/asyncrun.vim'
paq 'simeji/winresizer'
paq 't9md/vim-quickhl'
paq 'thinca/vim-qfreplace'
paq 'tyru/caw.vim'
paq 'tyru/capture.vim'

-- filetype
paq'kana/vim-altr'
paq'mattn/vim-maketable'
paq'dhruvasagar/vim-table-mode'
paq{'iamcco/markdown-preview.nvim', hook=vim.fn['mkdp#util#install()'] }

-- develop
paq'neovim/nvim-lspconfig'
paq'glepnir/lspsaga.nvim'
paq'hrsh7th/nvim-compe'
paq'hrsh7th/vim-vsnip'
paq'hrsh7th/vim-vsnip-integ'

-- ===========================================================================
-- Plugins config
-- ===========================================================================

-- appearance ================================================================
-- zephyr-nvim
vim.cmd [[ colorscheme nvcode ]]
function _G.colormod()
  vim.cmd [[
    hi! GitGutterAdd guifg=#B5CEA8
    hi! GitGutterChange guifg=#9CDCFE
    hi! GitGutterDelete guifg=#F44747
    hi! link GitGutterChabgeDelete GitGutterDelete
    hi! link LspDiagnosticsDefaultError TSError
    hi! link LspDiagnosticsDefaultWarning WarningMsg
    hi! LspDiagnosticsUnderlineError gui=underline
    hi! LspDiagnosticsUnderlineWarning gui=underline
  ]]
end
create_augroups({
  vimrc_colormod = {
    {"ColorScheme", "nvcode", "call v:lua.colormod()"},
  },
})

-- nvim-treesitter
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
  },
}

-- lualine.nvim
local lualine = require('lualine')
lualine.theme = 'codedark'
lualine.extensions = { 'fzf' }
lualine.status()

-- fuzzyfinder ===============================================================
-- fzf.vim
vim.g.fzf_command_prefix = 'Fzf'
nnoremap('<Leader>f', '<cmd>FzfFiles<CR>')
nnoremap('<Leader>l', '<cmd>FzfBLines<CR>')
vim.api.nvim_set_keymap('n', '<Leader>R', ':<C-u>FzfRg ', {noremap=true, silent=false})

-- enhanced ==================================================================
-- vim-eft
nmap(';', '<Plug>(eft-repeat)')
xmap(';', '<Plug>(eft-repeat)')
nmap('f', '<Plug>(eft-f)')
xmap('f', '<Plug>(eft-f)')
omap('f', '<Plug>(eft-f)')
nmap('F', '<Plug>(eft-F)')
xmap('F', '<Plug>(eft-F)')
omap('F', '<Plug>(eft-F)')
nmap('t', '<Plug>(eft-t)')
xmap('t', '<Plug>(eft-t)')
omap('t', '<Plug>(eft-t)')
nmap('T', '<Plug>(eft-T)')
xmap('T', '<Plug>(eft-T)')
omap('T', '<Plug>(eft-T)')

-- columnskip.vim
nmap('sj', '<Plug>(columnskip:nonblank:next)')
omap('sj', '<Plug>(columnskip:nonblank:next)')
xmap('sj', '<Plug>(columnskip:nonblank:next)')
nmap('sk', '<Plug>(columnskip:nonblank:prev)')
omap('sk', '<Plug>(columnskip:nonblank:prev)')
xmap('sk', '<Plug>(columnskip:nonblank:prev)')

-- lexima.vim
vim.g.lexima_ctrlh_as_backspace = 1

-- vim-operator-replace
map('R', '<Plug>(operator-replace)')

-- extension =================================================================
-- gitsigns.nvim
require('gitsigns').setup {
  signs = {
    add          = {hl = 'GitGutterAdd'   , text = '+'},
    change       = {hl = 'GitGutterChange', text = '!'},
    delete       = {hl = 'GitGutterDelete', text = '_'},
    topdelete    = {hl = 'GitGutterDelete', text = '‾'},
    changedelete = {hl = 'GitGutterChangeDelete', text = '~'},
  },
  keymaps = {
    noremap = true,
    buffer = true,
    ['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
    ['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},
    ['n <leader>ga'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
    ['n <leader>gr'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
    ['n <leader>gu'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
    ['n <leader>gp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
  },
  watch_index = {
    interval = 1000
  },
  sign_priority = 6,
  status_formatter = nil,
}

-- memolist.vim
vim.g.memolist_memo_suffix = 'md'
vim.g.memolist_template_dir_path = vim.fn.stdpath('config')..'/template/memotemplates'
vim.g.memolist_ex_cmd = 'FzfFiles'
nnoremap('<Leader>mn', '<cmd>MemoNew<CR>')
nnoremap('<Leader>ml', '<cmd>MemoList<CR>')
nnoremap('<Leader>mg', '<cmd>MemoGrep<CR>')

-- winresizer
vim.g.winresizer_start_key = '<C-w>'

-- vim-quickhl
nmap('<Space>m', '<Plug>(quickhl-manual-this)')
xmap('<Space>m', '<Plug>(quickhl-manual-this)')
nmap('<Space>M', '<Plug>(quickhl-manual-reset)')
xmap('<Space>M', '<Plug>(quickhl-manual-reset)')

-- caw.vim
nmap('<Space>c', '<Plug>(caw:hatpos:toggle)')
vmap('<Space>c', '<Plug>(caw:hatpos:toggle)')

-- filetype ==================================================================
-- vim-altr
create_augroups({
  vimrc_altr = {
    {"FileType", "go,vim,help", "nmap <buffer> <LocalLeader>a <Plug>(altr-forward)"};
    {"FileType", "go,vim,help", "nmap <buffer> <LocalLeader>b <Plug>(altr-back)"};
  }
})

-- vim-table-mode
vim.g.table_mode_corner = '|'
vim.g.table_mode_map_prefix = '<LocalLeader>'
vim.g.table_mode_toggle_map = 'tm'

-- markdown-preview.nvim
create_augroups({
  vimrc_altr = {
    {"FileType", "markdown", "nnoremap <buffer> <silent> <LocalLeader>p <cmd>MarkdownPreview<CR>"};
  }
})


-- develop ===================================================================
-- nvim-lspconfig
local nvim_lsp = require('lspconfig')
local custom_attach = function()
  local mapper = function (key, result)
    vim.api.nvim_buf_set_keymap(0, 'n', key, result, {silent=true, noremap=true})
  end
  mapper('gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('gD', '<Cmd>vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  mapper('gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  mapper('gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  mapper('<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>')
  mapper(']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
  mapper('[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
  mapper('<LocalLeader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  mapper('<LocalLeader>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  mapper('<LocalLeader>w', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  mapper('<LocalLeader>m', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('<LocalLeader>sl', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = true,
    signs = true,
    update_in_insert = false,
  }
)

local cap = {
  textDocument = {
    completion = {
      completionItem = {
        snippetSupport = true
      }
    }
  }
}
-- go
nvim_lsp.gopls.setup{
  capabilities = cap,
  cmd = {"gopls", "serve"},
  settings = {
    gopls = {
      usePlaceholders=true,
      gofumpt = true,
      analyses = {
        unusedparams = true,
      }
    },
  },
  on_attach=custom_attach
}

-- Synchronously organise (Go) imports.
function Goimports(timeoutms)
  local context = { source = { organizeImports = true } }
  vim.validate { context = { context, "t", true } }

  local params = vim.lsp.util.make_range_params()
  params.context = context

  local method = "textDocument/codeAction"
  local resp = vim.lsp.buf_request_sync(0, method, params, timeoutms)
  if resp and resp[1] then
    local result = resp[1].result
    if result and result[1] then
      local edit = result[1].edit
      vim.lsp.util.apply_workspace_edit(edit)
    end
  end

  vim.lsp.buf.formatting()
end

create_augroups({
  vimrc_goimports = {
    {"BufWritePre", "*.go", "lua Goimports(1000)"};
  };
})

-- bash
nvim_lsp.bashls.setup{
  on_attach=custom_attach
}

-- vim
nvim_lsp.vimls.setup{
  capabilities = cap,
  on_attach=custom_attach
}

-- yaml
nvim_lsp.yamlls.setup{
  capabilities = cap,
  on_attach=custom_attach,
  settings = {
    yaml = {
      schemas = {
        ['https://json.schemastore.org/cloudbuild'] = 'cloudbuild*.yaml',
        ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
      },
      format = {
        enable = true,
        singleQuote = true
      },
      completion = true,
    }
  }
}

--lua
local system_name
if vim.fn.has("mac") == 1 then
  system_name = "macOS"
elseif vim.fn.has("unix") == 1 then
  system_name = "Linux"
else
  print("Unsupported system for sumneko")
end
local sumneko_root_path = vim.fn.stdpath('cache')..'/lspconfig/sumneko_lua/lua-language-server'
local sumneko_binary = sumneko_root_path.."/bin/"..system_name.."/lua-language-server"
nvim_lsp.sumneko_lua.setup{
  on_attach=custom_attach,
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';'),
      },
      diagnostics={
        enable=true,
        globals={
          "vim"
        },
      },
      workspace = {
        library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        },
      },
    }
  }
}

-- efm-langserver
nvim_lsp.efm.setup{
  filetypes = {"markdown", "sh"};
}

-- lspsaga.nvim
require'lspsaga'.init_lsp_saga()

-- nvim-lspfuzzy
require('lspfuzzy').setup {}
nnoremap('<LocalLeader>d', '<cmd>LspDiagnosticsAll<CR>')

-- nvim-compe
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  allow_prefix_unmatch = true;

  source = {
    path = true;
    buffer = true;
    vsnip = true;
    nvim_lsp = true;
    nvim_lua = false;
  };
}
vim.api.nvim_set_keymap('i', '<CR>', [[compe#confirm('<CR>')]], {noremap=true, silent=true, expr=true})
vim.api.nvim_set_keymap('i', '<C-e>', [[compe#close('<C-e>')]], {noremap=true, silent=true, expr=true})

-- vim-vsnip
vim.api.nvim_set_keymap('i', '<C-l>', [[vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']], {expr=true})
vim.api.nvim_set_keymap('s', '<C-l>', [[vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']], {expr=true})
vim.api.nvim_set_keymap('i', '<Tab>', [[vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>']], {expr=true})
vim.api.nvim_set_keymap('s', '<Tab>', [[vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>']], {expr=true})
vim.api.nvim_set_keymap('i', '<S-Tab>', [[vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>']], {expr=true})
vim.api.nvim_set_keymap('s', '<S-Tab>', [[vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>']], {expr=true})
vim.g.vsnip_snippet_dir = vim.fn.stdpath('config')..'/snippets'

function _G.check_back_space()
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    return true
  else
    return false
  end
end

vim.api.nvim_set_keymap(
  'i',
  '<Tab>',
  [[pumvisible() ? compe#confirm('<C-e>') : vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : v:lua.check_back_space() ? "\<TAB>" : compe#complete()]],
  {silent=true,expr=true}
)
