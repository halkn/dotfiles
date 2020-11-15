" ============================================================================
" Global variables
" ============================================================================
" Disable default plugin
let g:loaded_gzip               = 1
let g:loaded_tar                = 1
let g:loaded_tarPlugin          = 1
let g:loaded_zip                = 1
let g:loaded_zipPlugin          = 1
let g:loaded_rrhelper           = 1
let g:loaded_vimball            = 1
let g:loaded_vimballPlugin      = 1
let g:loaded_getscript          = 1
let g:loaded_getscriptPlugin    = 1
let g:loaded_netrw              = 1
let g:loaded_netrwPlugin        = 1
let g:loaded_netrwSettings      = 1
let g:loaded_netrwFileHandlers  = 1
let g:did_install_default_menus = 1
let g:skip_loading_mswin        = 1
let g:did_install_syntax_menu   = 1
let g:loaded_2html_plugin       = 1

" map leader
let g:mapleader = "\<Space>"
let g:maplocalleader = ','

" indent for Line continuation.(\)
let g:vim_indent_cont = 0

" markdown syntax
let g:markdown_fenced_languages = [
\  'go',
\  'sh',
\  'json',
\  'yaml',
\  'lua',
\  'vim',
\]

" ============================================================================
" Global options
" ============================================================================
set encoding=utf-8
scriptencoding utf-8

" Encoding
set fileencodings=utf-8,cp932
set fileformats=unix,dos,mac

" Don't creat swap files
set nobackup
set noswapfile
set noundofile

" Appearance
set wildmenu
set display=lastline
set laststatus=2
set nocursorcolumn
set nocursorline
set wrap
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set synmaxcol=256
set showcmd
set signcolumn=yes
set noshowmode
set showtabline=2
set background=dark
set diffopt^=vertical

" buffer
set hidden
set switchbuf=useopen

" edit
set smarttab
set expandtab
set autoindent
set shiftwidth=4
set shiftround
set tabstop=4
set virtualedit=block,onemore
set whichwrap=b,s,[,],<,>
set backspace=indent,eol,start

" window
set splitbelow
set splitright
set winwidth=30
set winheight=1
set cmdwinheight=5
set noequalalways

" search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Completion
set completeopt=menuone,noinsert,noselect

" shortmess
set shortmess+=c
set shortmess-=S

" help
set helplang=ja,en

" clipborad
if has('clipboard')
  set clipboard=unnamedplus
endif

" undo
if has("persistent_undo")
  set undodir=$XDG_CACHE_HOME/nvim/.undodir
  set undofile
endif

" Use true color in terminal
if exists('&termguicolors')
  set termguicolors
endif

" grep
if executable('rg')
  let &grepprg = 'rg --vimgrep --hidden'
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

if has('nvim')
  set inccommand=split
  set pumblend=20
endif

" ============================================================================
" Mapping
" ============================================================================
" reload vimrc
nnoremap <Space>s :source $MYVIMRC<CR>

" Clear search highlight
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>

" Multi line move
noremap k gk
noremap j gj
noremap gk k
noremap gj j
noremap <Down> gj
noremap <Up> gk

" Move cursor like emacs in Insert Mode
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-a> <C-o>^
inoremap <C-e> <End>
inoremap <C-d> <Del>

" Move cursor like emacs in Insert Mode
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-a> <HOME>
cnoremap <C-e> <END>

" Move cursor the begining and end of line
nnoremap H ^
nnoremap L $
vnoremap H ^
vnoremap L $

" Move between windows
nnoremap <tab>   <c-w>w
nnoremap <S-tab> <c-w>W

" Not yank is delete operation
nnoremap x "_x
nnoremap X "_X

" Indent in visual and select mode automatically re-selects.
vnoremap > >gv
vnoremap < <gv

" Quit the current window
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <Esc>:q<CR>
tnoremap <silent> <C-q> <C-\><C-n>:q!<CR>

" open termianl in vertial split,new tab,current winddow
nnoremap <silent> <Leader>ts :<C-u>split term://$SHELL<CR>
nnoremap <silent> <Leader>tv :<C-u>vsplit term://$SHELL<CR>
nnoremap <silent> <Leader>tt :<C-u>tabnew term://$SHELL<CR>
nnoremap <silent> <Leader>tw :<C-u>terminal<CR>

" ESC in terminal-mode.
tnoremap <silent> <Esc> <C-\><C-n>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>o [Toggle]
nnoremap <silent> [Toggle]n :<C-u>setlocal number! number?<CR>
nnoremap <silent> [Toggle]rn :<C-u>setlocal relativenumber! relativenumber?<CR>
nnoremap <silent> [Toggle]c :<C-u>setlocal cursorline! cursorcolumn!<CR>
nnoremap <silent> [Toggle]w :<C-u>setlocal wrap! wrap?<CR>
nnoremap <silent> [Toggle]p :<C-u>set paste! paste?<CR>

" Shortening for ++enc=
cnoreabbrev ++u ++enc=utf8
cnoreabbrev ++c ++enc=cp932
cnoreabbrev ++s ++enc=sjis

" quickfix
nnoremap <silent> [q :<C-u>cprev<CR>
nnoremap <silent> ]q :<C-u>cnext<CR>

function! ToggleQuickfix()
  let l:nr = winnr('$')
  cwindow
  let l:nr2 = winnr('$')
  if l:nr == l:nr2
      cclose
  endif
endfunction
nnoremap <script> <silent> Q :call ToggleQuickfix()<CR>

" locationlist
nnoremap <silent> [l :lprevious<CR>
nnoremap <silent> ]l :lnext<CR>

function! ToggleLocationList()
  let l:nr = winnr('$')
  lwindow
  let l:nr2 = winnr('$')
  if l:nr == l:nr2
      lclose
  endif
endfunction
nnoremap <script> <silent> W :call ToggleLocationList()<CR>

" ============================================================================
" autocmd
" ============================================================================
" open help in vertical window.
function! s:helpvert()
  if &buftype == 'help'
    wincmd L
  endif
endfunction
augroup vimrc_au
  autocmd!
  autocmd FileType gitcommit setlocal spell spelllang=cjk,en
  autocmd FileType git setlocal nofoldenable
  autocmd FileType text setlocal textwidth=0
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2
  autocmd FileType lua setlocal tabstop=2 shiftwidth=2
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2
  autocmd FileType zsh setlocal tabstop=2 shiftwidth=2
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2
  autocmd FileType json setlocal tabstop=2 shiftwidth=2
  autocmd FileType qf setlocal signcolumn=no
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
  autocmd BufEnter *.txt,*.jax call s:helpvert()
  autocmd FileType help setlocal signcolumn=no
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
  autocmd FileType help nnoremap <buffer> <CR> <C-]>
  autocmd FileType help nnoremap <buffer> <BS> <C-T>
  autocmd TermOpen * setlocal signcolumn=no nolist
  autocmd TermOpen * startinsert
  autocmd TextYankPost * silent! lua return (not vim.v.event.visual) and require'vim.highlight'.on_yank()
augroup END

" ============================================================================
" Plugin
" ============================================================================
call plug#begin(stdpath('data') . '/plugged')
" global
Plug 'chuling/vim-equinusocio-material'
Plug 'itchyny/lightline.vim'
Plug 'itchyny/vim-gitbranch'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'hrsh7th/vim-eft'
Plug 'tyru/columnskip.vim'
Plug 'cohama/lexima.vim'
" develop
Plug 'mhinz/vim-signify'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
" filetype
Plug 'kana/vim-altr', { 'for': [ 'go', 'vim' ] }
" extension
Plug 'skywind3000/asyncrun.vim', { 'on': 'AsyncRun' }
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew', 'MemoList', 'MemoGrep'] }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 't9md/vim-quickhl', { 'on': '<Plug>(quickhl-manual-this)' }
Plug 'thinca/vim-qfreplace', { 'on': 'Qfreplace' }
Plug 'tweekmonster/startuptime.vim', { 'on': 'StartupTime' }
Plug 'tyru/caw.vim', { 'on': '<Plug>(caw:hatpos:toggle)' }
Plug 'tyru/capture.vim', { 'on': 'Capture' }
" lua
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'RishabhRD/popfix'
Plug 'RishabhRD/nvim-lsputils'
call plug#end()

" ============================================================================
" Plugin Config
" ============================================================================
" global ---------------------------------------------------------------------
" vim-equinusocio-material
let g:equinusocio_material_style = 'darker'
let g:equinusocio_material_bracket_improved = 1
colorscheme equinusocio_material

" lightline.vim
let g:lightline = {
\ 'colorscheme': 'equinusocio_material',
\ 'tabline': {
\   'left':  [ ['tabs'] ],
\   'right': [ ['close'], ['cwd', 'gitbranch'] ],
\ },
\ 'active': {
\   'left': [ [ 'mode', 'paste'],
\             [ 'readonly', 'filename', 'modified' ] ],
\   'right': [ [ 'lineinfo' ],
\              [ 'percent' ],
\              [ 'fileformat', 'fileencoding', 'filetype' ] ]
\ },
\ 'component_function': {
\   'gitbranch': 'gitbranch#name',
\   'cwd':       'getcwd'
\ },
\ }

" vim-operator-replace
map R <Plug>(operator-replace)

" vim-eft
nmap ; <Plug>(eft-repeat)
xmap ; <Plug>(eft-repeat)
nmap f <Plug>(eft-f)
xmap f <Plug>(eft-f)
omap f <Plug>(eft-f)
nmap F <Plug>(eft-F)
xmap F <Plug>(eft-F)
omap F <Plug>(eft-F)
nmap t <Plug>(eft-t)
xmap t <Plug>(eft-t)
omap t <Plug>(eft-t)
nmap T <Plug>(eft-T)
xmap T <Plug>(eft-T)
omap T <Plug>(eft-T)

" columnskip.vim
nmap sj <Plug>(columnskip:nonblank:next)
omap sj <Plug>(columnskip:nonblank:next)
xmap sj <Plug>(columnskip:nonblank:next)
nmap sk <Plug>(columnskip:nonblank:prev)
omap sk <Plug>(columnskip:nonblank:prev)
xmap sk <Plug>(columnskip:nonblank:prev)

" lexima.vim
let g:lexima_ctrlh_as_backspace = 1

" develop --------------------------------------------------------------------
" vim-signify
nnoremap <silent> <C-y>      :SignifyToggle<CR>
nnoremap <silent> <leader>gd :SignifyDiff<cr>
nnoremap <silent> <leader>gp :SignifyHunkDiff<cr>
nnoremap <silent> <leader>gu :SignifyHunkUndo<cr>

" vim-vsnip
imap <expr> <C-l>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-l>'
smap <expr> <C-l>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-l>'
imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
let g:vsnip_snippet_dir = expand(fnamemodify($MYVIMRC, ":h") . '/snippets')

" filetype --------------------------------------------------------------------
" vim-altr
augroup vimrc_altr
  au!
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>a <Plug>(altr-forward)
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>b <Plug>(altr-back)
augroup END

" extension ------------------------------------------------------------------
" asyncrun.vim
let g:asyncrun_open = 8
command! -nargs=* Grep AsyncRun -program=grep -strip <f-args>

function s:asyncrun_gotest_func() abort
  let l:test = search('func \(Test\|Example\)', "bcnW")

  if l:test == 0
    echo "[test] no test found immediate to cursor"
    return
  end

  let l:line = getline(test)
  let l:name = split(split(line, " ")[1], "(")[0]
  execute('AsyncRun -mode=term -pos=right -cols=80 -focus=0 -cwd=$(VIM_FILEDIR) go test -v -run ' . l:name)
endfunction

function s:asyncrun_go_setup() abort
  command! -buffer -nargs=* -complete=dir GoRun
  \ AsyncRun -mode=term -pos=right -cols=80 -focus=0  go run $VIM_RELNAME
  command! -buffer -nargs=* -complete=dir GoTest
  \ AsyncRun -mode=term -pos=right -cols=80 -focus=0 go test <f-args>
  command! -buffer -nargs=0 GoTestPackage GoTest ./$VIM_RELDIR
  command! -buffer -nargs=0 GoTestFunc call s:asyncrun_gotest_func()

  nnoremap <silent> <buffer> <LocalLeader>r :<C-u>GoRun<CR>
  nnoremap <silent> <buffer> <LocalLeader>t :<C-u>GoTest ./...<CR>
  nnoremap <silent> <buffer> <LocalLeader>p :<C-u>GoTestPackage<CR>
  nnoremap <silent> <buffer> <LocalLeader>f :<C-u>GoTestFunc<CR>
endfunction

augroup vimrc_asyncrun
  au!
  autocmd FileType go call s:asyncrun_go_setup()
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 bash $VIM_RELNAME<CR>
augroup END

" memolist.vim
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = expand(fnamemodify($MYVIMRC, ":h") . '/template/memotemplates')
let g:memolist_ex_cmd = 'Files'
nnoremap <Leader>mn :<C-u>MemoNew<CR>
nnoremap <Leader>mg :<C-u>MemoGrep<CR>
nnoremap <Leader>ml :<C-u>MemoList<CR>

" caw.vim
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent> <C-w>r :WinResizerStartResize<CR>

" vim-quickhl
nmap <Space>m <Plug>(quickhl-manual-this)
xmap <Space>m <Plug>(quickhl-manual-this)
nmap <Space>M <Plug>(quickhl-manual-reset)
xmap <Space>M <Plug>(quickhl-manual-reset)

" lua ------------------------------------------------------------------------
luafile ~/.config/nvim/init.lua
