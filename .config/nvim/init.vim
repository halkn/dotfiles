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

" clipborad
set clipboard=unnamedplus

" Completion
set completeopt=menuone,noinsert,noselect

" shortmess
set shortmess+=c
set shortmess-=S

" help
set helplang=en

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
" Plugin
" ============================================================================
call plug#begin(stdpath('data') . '/plugged')
" global
Plug 'chuling/vim-equinusocio-material'
" Plug '/Users/haruki/dev/github.com/halkn/vim-equinusocio-material'
Plug 'halkn/tender.vim'
Plug 'itchyny/lightline.vim'
Plug 'mattn/vim-findroot'
Plug 'cohama/lexima.vim'
Plug 'tyru/columnskip.vim'
Plug 'tyru/caw.vim'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" LSP
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'prabirshrestha/vim-lsp'
" Plug 'mattn/vim-lsp-settings'
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
" Develop
Plug 'liuchengxu/vista.vim', { 'on': ['Vista!!', 'Vista'] }
Plug 'skywind3000/asyncrun.vim', { 'on': 'AsyncRun' }
Plug 'kana/vim-altr'
" FileType
Plug 'dhruvasagar/vim-table-mode', { 'for': 'markdown' }
Plug 'iamcco/markdown-preview.nvim', 
\ { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
" Extension
Plug 'mhinz/vim-signify'
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew', 'MemoList', 'MemoGrep'] }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 'voldikss/vim-floaterm', { 'on': ['FloatermToggle', 'FloatermNew'] }
Plug 'tyru/capture.vim', { 'on': 'Capture' }
Plug 'rhysd/git-messenger.vim', { 'on': '<Plug>(git-messenger)' }
Plug 'thinca/vim-qfreplace', { 'on': 'Qfreplace' }
Plug 't9md/vim-quickhl', { 'on': '<Plug>(quickhl-manual-this)' }
Plug 'tweekmonster/startuptime.vim', {'on': 'StartupTime'}
call plug#end()

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

" Disable s operation
nnoremap s <Nop>
vnoremap s <Nop>

" Indent in visual and select mode automatically re-selects.
vnoremap > >gv
vnoremap < <gv

" Quit the current window
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <Esc>:q<CR>
tnoremap <silent> <C-q> <C-\><C-n>:q!<CR>

" open termianl in vertial split,new tab,current winddow
nnoremap <silent> <Leader>ts :<C-u>split <BAR> terminal<CR> i
nnoremap <silent> <Leader>tv :<C-u>vsplit <BAR> terminal<CR> i
nnoremap <silent> <Leader>tt :<C-u>tabnew <BAR> terminal<CR> i
nnoremap <silent> <Leader>tw :<C-u>terminal<CR> i

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
" indent by FileType
augroup vimrc-ft-indent
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
augroup END

" quickfix
augroup vimrc-ft-quickfix
  autocmd!
  autocmd FileType qf setlocal signcolumn=no
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
augroup END

" vim help
augroup vimrc-ft-help
  autocmd!
  autocmd FileType help wincmd L
  autocmd FileType help setlocal signcolumn=no
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
  autocmd FileType help nnoremap <buffer> <CR> <C-]>
  autocmd FileType help nnoremap <buffer> <BS> <C-T>
augroup END

" yank hightlight
augroup vimrc_LuaHighlight
  au!
  au TextYankPost * silent! lua return (not vim.v.event.visual) and require'vim.highlight'.on_yank()
augroup END

" ============================================================================
" Plugin config
" ============================================================================
" Global ---------------------------------------------------------------------
let g:equinusocio_material_style = 'darker'
let g:equinusocio_material_bracket_improved = 1
colorscheme equinusocio_material
hi PMenu guibg=#2f2f2f
hi CocFloating guibg=#2f2f2f

" lightline
let g:lightline = {
\ 'colorscheme': 'equinusocio_material',
\ 'active': {
\   'left': [ [ 'mode', 'paste'],
\             [ 'readonly', 'filename', 'modified' ], ['gitbranch'] ],
\   'right': [ [ 'lineinfo', 'cocstatus' ],
\              [ 'percent' ],
\              [ 'fileformat', 'fileencoding', 'filetype' ] ]
\ },
\ 'component_function': {
\   'cocstatus': 'coc#status',
\   'gitbranch': 'LightlineGitBranch',
\ },
\ }

function! LightlineGitBranch() abort
  return get(g:, 'coc_git_status', '')
endfunction

" lexima.vim
let g:lexima_ctrlh_as_backspace = 1

" caw.vim
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" vim-operator-replace
map R <Plug>(operator-replace)

" columnskip.vim
nmap sj <Plug>(columnskip:nonblank:next)
omap sj <Plug>(columnskip:nonblank:next)
xmap sj <Plug>(columnskip:nonblank:next)
nmap sk <Plug>(columnskip:nonblank:prev)
omap sk <Plug>(columnskip:nonblank:prev)
xmap sk <Plug>(columnskip:nonblank:prev)

" fzf.vim --------------------------------------------------------------------
let g:fzf_command_prefix = 'Fzf'
let g:fzf_preview_window = 'right:60%'
let g:fzf_layout = { 'window': { 'width': 0.95, 'height': 0.9 } }

" files
command! -bang -nargs=? -complete=dir FzfFiles
\ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

" ripgrep
command! -bang -nargs=* FzfRg
\ call fzf#vim#grep(
\   'rg --column --line-number --no-heading --color=always --smart-case --hidden -- '.shellescape(<q-args>),
\   1,
\   fzf#vim#with_preview(), <bang>0
\ )

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --hidden --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang FzfRG call RipgrepFzf(<q-args>, <bang>0)

nnoremap <silent> <Leader><Leader> :<C-u>FzfHistory<CR>
nnoremap <silent> <Leader>f        :<C-u>FzfFiles<CR>
nnoremap <silent> <Leader>b        :<C-u>FzfBuffers<CR>
nnoremap <silent> <Leader>l        :<C-u>FzfBLines<CR>
nnoremap <silent> <Leader>R        :<C-u>FzfRG<CR>
nnoremap <silent> <Leader>gs       :<C-u>FzfGStatus<CR>
nnoremap <silent> <Leader>gl       :<C-u>FzfCommits<CR>
inoremap <expr>   <c-x><c-k>       fzf#vim#complete#word({'left': '15%'})

augroup vimrc_fzf
  au!
  autocmd FileType fzf tnoremap <buffer> <silent> <Esc> <Esc>
augroup END

" LSP ------------------------------------------------------------------------
lua require('lsp_config')
let g:completion_enable_snippet = 'vim-vsnip'
let g:completion_confirm_key = "\<C-l>"

" vim-vsnip
imap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
smap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
imap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
let g:vsnip_snippet_dir = expand(fnamemodify($MYVIMRC, ":h") . '/snippets')

" Develop --------------------------------------------------------------------
" vista.vim
let g:vista_default_executive = 'vim_lsp'
let g:vista_executive_for = {
\ 'markdown': 'toc',
\ }
let g:vista_close_on_jump = 1
let g:vista#renderer#enable_icon = 0
let g:vista_fzf_preview = ['right:60%']
let g:vista_echo_cursor_strategy = 'floating_win'
nnoremap <silent> <leader>vt :<c-u>Vista!!<CR>

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
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 sh $VIM_RELNAME<CR>
augroup END

" vim-altr
augroup vimrc_altr
  au!
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>a <Plug>(altr-forward)
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>b <Plug>(altr-back)
augroup END

" ----------------------------------------------------------------------------
" FileType
" ----------------------------------------------------------------------------
" vim-table-mode
let g:table_mode_corner = '|'
let g:table_mode_map_prefix = '<LocalLeader>'

" markdown-preview.nvim
augroup vimrc_markdown_preview.nvim
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p :<C-u>MarkdownPreview<CR>
augroup END

" ----------------------------------------------------------------------------
" Extention
" ----------------------------------------------------------------------------
" memolist.vim
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = expand(fnamemodify($MYVIMRC, ":h") . '/template/memotemplates')
let g:memolist_ex_cmd = 'FzfFiles'
nnoremap <Leader>mn :<C-u>MemoNew<CR>
nnoremap <Leader>mg :<C-u>MemoGrep<CR>
nnoremap <Leader>ml :<C-u>MemoList<CR>

" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent> <C-w>r :WinResizerStartResize<CR>

" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
noremap <silent> <Leader>gd :SignifyDiff<CR>

" vim-floaterm
let g:floaterm_autoclose = 2
let g:floaterm_width = 0.9
let g:floaterm_height = 0.9
nnoremap <silent> <F7>  :FloatermNew<CR>
tnoremap <silent> <F7>  <C-\><C-n>:FloatermNew<CR>
nnoremap <silent> <F8>  :FloatermPrev<CR>
tnoremap <silent> <F8>  <C-\><C-n>:FloatermPrev<CR>
nnoremap <silent> <F9>  :FloatermNext<CR>
tnoremap <silent> <F9>  <C-\><C-n>:FloatermNext<CR>
nnoremap <silent> <C-t> :FloatermToggle<CR>
tnoremap <silent> <C-t> <C-\><C-n>:FloatermToggle<CR>
" 
" git-messenger.vim
nmap <Leader>gm <Plug>(git-messenger)
function! s:setup_git_messenger_popup() abort
  nmap <buffer> <CR> o
  nmap <buffer> <BS> O
endfunction
augroup vimrc_git_messenger
  au!
  autocmd FileType gitmessengerpopup call s:setup_git_messenger_popup()
augroup END

" vim-quickhl
nmap <Space>m <Plug>(quickhl-manual-this)
xmap <Space>m <Plug>(quickhl-manual-this)
nmap <Space>M <Plug>(quickhl-manual-reset)
xmap <Space>M <Plug>(quickhl-manual-reset)
