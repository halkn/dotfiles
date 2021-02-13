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

" use lua syntax in .vim file
let g:vimsyn_embed = 'l'

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
set nowrap
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

" time
set ttimeoutlen=10

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
  set pumblend=10
endif

" ============================================================================
" Mapping
" ============================================================================
" reload vimrc
nnoremap <Space>s :source $MYVIMRC<CR>

" Clear search highlight
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>
nnoremap <silent> <C-l> :<C-u>nohlsearch<CR><C-l>

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

" Move cursor like emacs in Cmdline-mode
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-a> <HOME>
cnoremap <C-e> <END>

" forward match from cmdline history
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

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
nnoremap <silent> <Leader>ts <cmd>split term://$SHELL<CR>
nnoremap <silent> <Leader>tv <cmd>vsplit term://$SHELL<CR>
nnoremap <silent> <Leader>tt <cmd>tabnew term://$SHELL<CR>
nnoremap <silent> <Leader>tw <cmd>terminal<CR>

" ESC in terminal-mode.
tnoremap <silent> <Esc> <C-\><C-n>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>o [Toggle]
nnoremap <silent> [Toggle]n  <cmd>setlocal number! number?<CR>
nnoremap <silent> [Toggle]rn <cmd>setlocal relativenumber! relativenumber?<CR>
nnoremap <silent> [Toggle]c  <cmd>setlocal cursorline! cursorcolumn!<CR>
nnoremap <silent> [Toggle]w  <cmd>setlocal wrap! wrap?<CR>
nnoremap <silent> [Toggle]p  <cmd>set paste! paste?<CR>

" quickfix/loclist
nnoremap <silent> [q <cmd>cprev<CR>
nnoremap <silent> ]q <cmd>cnext<CR>
nnoremap <silent> [l :lprevious<CR>
nnoremap <silent> ]l :lnext<CR>
function! s:toggleqf(mode) abort
  if a:mode == 'q'
    let l:open = 'cwindow'
    let l:close = 'cclose'
  else
    let l:open = 'lwindow'
    let l:close = 'lclose'
  endif
  let l:nr = winnr('$')
  execute(l:open)
  let l:nr2 = winnr('$')
  if l:nr == l:nr2
      execute(l:close)
  endif
endfunction
nnoremap <script> <silent> Q <cmd>call <SID>toggleqf('q')<CR>
nnoremap <script> <silent> W <cmd>call <SID>toggleqf('l')<CR>

" ============================================================================
" autocmd
" ============================================================================
" open help in vertical window.
function! s:helpvert()
  if &buftype == 'help'
    wincmd L
  endif
endfunction
function! s:qfenter(cmd)
  let l:lnum = line('.')
  if get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    let l:cmd = 'll'
    let l:ccmd = 'lclose'
  else
    let l:cmd = 'cc'
    let l:ccmd = 'cclose'
  endif
  silent! execute a:cmd
  silent! execute l:cmd l:lnum
  silent! execute l:ccmd
endfunction
augroup vimrc_filetype
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
  autocmd Filetype qf nnoremap <silent> <buffer> <C-m> <cmd>call <SID>qfenter('wincmd p')<CR>
  autocmd Filetype qf nnoremap <silent> <buffer> <C-t> <cmd>call <SID>qfenter('tabnew')<CR>
  autocmd Filetype qf nnoremap <silent> <buffer> <C-x> <cmd>call <SID>qfenter('wincmd p <bar> new')<CR>
  autocmd Filetype qf nnoremap <silent> <buffer> <C-v> <cmd>call <SID>qfenter('wincmd p <bar> vnew')<CR>
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
" abbrev
" ============================================================================
" Shortening for ++enc=
cnoreabbrev ++u ++enc=utf8
cnoreabbrev ++c ++enc=cp932
cnoreabbrev ++s ++enc=sjis

" ============================================================================
" Plugin
" ============================================================================
call plug#begin(stdpath('data') . '/plugged')
" colorscheme
Plug 'christianchiarulli/nvcode-color-schemes.vim'

" enhanced
Plug 'itchyny/lightline.vim'
Plug 'hrsh7th/vim-eft'
Plug 'tyru/columnskip.vim'
Plug 'cohama/lexima.vim'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'mattn/vim-findroot'

" git

" filetype
Plug 'kana/vim-altr', { 'for': [ 'go', 'vim', 'help' ] }
Plug 'mattn/vim-maketable', { 'for': 'markdown' }
Plug 'dhruvasagar/vim-table-mode', { 'for': 'markdown' }
Plug 'iamcco/markdown-preview.nvim', 
\ { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

" extension
Plug 'glidenote/memolist.vim', { 'on': [ 'MemoNew', 'MemoGrep', 'MemoList' ] }
Plug 'skywind3000/asyncrun.vim', { 'on': 'AsyncRun' }
Plug 'skanehira/translate.vim', { 'on': [ '<Plug>(VTranslate)', '<Plug>(VTranslateBang)' ] }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 't9md/vim-quickhl', { 'on': '<Plug>(quickhl-manual-this)' }
Plug 'thinca/vim-qfreplace', { 'on': 'Qfreplace' }
Plug 'tyru/caw.vim', { 'on': '<Plug>(caw:hatpos:toggle)' }
Plug 'tyru/capture.vim', { 'on': 'Capture' }
Plug 'tweekmonster/startuptime.vim', { 'on': 'StartupTime' }

" fuzzy finder
Plug 'Shougo/denite.nvim', { 'do': ':UpdateRemotePlugins', 'on': 'Denite' }

" completion
Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'

call plug#end()


" ============================================================================
" Plugin config
" ============================================================================
" colorscheme ----------------------------------------------------------------
colorscheme nvcode
hi! GitGutterAdd guifg=#B5CEA8
hi! GitGutterChange guifg=#9CDCFE
hi! GitGutterDelete guifg=#F44747
hi! link GitGutterChabgeDelete GitGutterDelete

" enhanced -------------------------------------------------------------------
" lightline.vim
let g:lightline = {}
let g:lightline.colorscheme = 'wombat'
" columnskip.vim
nmap sj <Plug>(columnskip:nonblank:next)
omap sj <Plug>(columnskip:nonblank:next)
xmap sj <Plug>(columnskip:nonblank:next)
nmap sk <Plug>(columnskip:nonblank:prev)
omap sk <Plug>(columnskip:nonblank:prev)
xmap sk <Plug>(columnskip:nonblank:prev)

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


" lexima.vim
let g:lexima_ctrlh_as_backspace = 1

" vim-operator-replace
map R <Plug>(operator-replace)

" filetype -------------------------------------------------------------------
" vim-altr
augroup vimrc_altr
  au!
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>a <Plug>(altr-forward)
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>b <Plug>(altr-back)
augroup END

" vim-table-mode
let g:table_mode_corner = '|'
let g:table_mode_map_prefix = '<LocalLeader>'
let g:table_mode_toggle_map = 'tm'

" markdown-preview.nvim
augroup vimrc_markdown_preview
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p <cmd>MarkdownPreview<CR>
augroup END

" extension ------------------------------------------------------------------
" memolist.vim
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path =
\ expand(fnamemodify($MYVIMRC, ":h") . '/template/memotemplates')
let g:memolist_ex_cmd = 'FzfFiles'
nnoremap <Leader>mn <cmd>MemoNew<CR>
nnoremap <Leader>mg <cmd>MemoGrep<CR>
nnoremap <Leader>ml <cmd>MemoList<CR>

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

  nnoremap <silent> <buffer> <LocalLeader>r <cmd>GoRun<CR>
  nnoremap <silent> <buffer> <LocalLeader>t <cmd>GoTest ./...<CR>
  nnoremap <silent> <buffer> <LocalLeader>p <cmd>GoTestPackage<CR>
  nnoremap <silent> <buffer> <LocalLeader>f <cmd>GoTestFunc<CR>
endfunction

augroup vimrc_asyncrun
  au!
  autocmd FileType go call s:asyncrun_go_setup()
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ <cmd>AsyncRun -mode=term -pos=right -cols=80 -focus=0 bash $VIM_RELNAME<CR>
augroup END


" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent> <C-w>r <cmd>WinResizerStartResize<cr>

" vim-quickhl
nmap <Space>m <Plug>(quickhl-manual-this)
xmap <Space>m <Plug>(quickhl-manual-this)
nmap <Space>M <Plug>(quickhl-manual-reset)
xmap <Space>M <Plug>(quickhl-manual-reset)

" caw.vim
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" fuzzy finder ---------------------------------------------------------------
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>    denite#do_map('do_action')
  nnoremap <silent><buffer><expr> a       denite#do_map('choose_action')
  nnoremap <silent><buffer><expr> d       denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p       denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> q       denite#do_map('quit')
  nnoremap <silent><buffer><expr> <ESC>   denite#do_map('quit')
  nnoremap <silent><buffer><expr> i       denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <Space> denite#do_map('toggle_select').'j'
endfunction
function! s:denite_filter_my_settings() abort
  inoremap <silent><buffer> <C-j> <Esc><C-w>p:call cursor(line('.')+1,0)<CR><C-w>pA
  inoremap <silent><buffer> <C-k> <Esc><C-w>p:call cursor(line('.')-1,0)<CR><C-w>pA
  inoremap <silent><buffer><expr> <ESC>   denite#do_map('quit')
  nnoremap <silent><buffer><expr> <ESC>   denite#do_map('quit')
  inoremap <silent><buffer><expr> <C-c>   denite#do_map('quit')
endfunction
function! s:denite_init() abort
  call denite#custom#var('file/rec', 'command',
  \ ['fd', '--type', 'file', '--follow', '--hidden', '--exclude', '.git', '.*']
  \ )
  call denite#custom#var('grep,line/external', {
  \ 'command': ['rg', '--threads', '1'],
  \ 'recursive_opts': [],
  \ 'final_opts': [],
  \ 'separator': ['--'],
  \ 'default_opts': ['-i', '--vimgrep', '--no-heading', '--hidden'],
  \ })
  call denite#custom#option('default', {
  \ 'source_names': 'short',
  \ 'winheight': 12,
  \ 'vertical_preview': v:true,
  \ 'prompt': '> ',
  \ 'preview_width': 80,
  \ 'statusline': v:false,
  \ })
endfunction

augroup vimrc_denite
  au!
  autocmd User denite.nvim call s:denite_init()
  autocmd FileType denite call s:denite_my_settings()
  autocmd FileType denite-filter call s:denite_filter_my_settings()
augroup END

nnoremap <silent> <Leader>f <cmd>Denite file/rec -start-filter<CR>
nnoremap <silent> <Leader>l <cmd>Denite line -start-filter<CR>
nnoremap <silent> <Leader>b <cmd>Denite buffer<CR>
nnoremap <silent> <Leader>R <cmd>Denite grep -auto-action=preview<CR>

" completion -----------------------------------------------------------------
" nvim-compe
let g:compe = {}
let g:compe.enabled = v:true
let g:compe.preselect = 'disable'
let g:compe.allow_prefix_unmatch = v:true
let g:compe.source = {}
let g:compe.source.path = v:true
let g:compe.source.buffer = v:true
let g:compe.source.vsnip = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
inoremap <silent><expr> <CR>  compe#confirm('<CR>')
inoremap <silent><expr> <C-e> compe#close('<C-e>')

" vim-vsnip
imap <expr> <C-l>   vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l>   vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
imap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
let g:vsnip_snippet_dir = expand(fnamemodify($MYVIMRC, ":h") . '/snippets')

" Make <tab> used for
" trigger completion, completion confirm, snippet expand and jump like VSCode.
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
imap <silent><expr> <Tab>
\ pumvisible() ? compe#confirm('<C-e>') :
\ vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' :
\ <SID>check_back_space() ? "\<TAB>" :
\ compe#complete()
