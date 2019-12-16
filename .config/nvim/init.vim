" ============================================================================
" Init {{{
" ============================================================================
set encoding=utf-8
scriptencoding utf-8

let mapleader = "\<Space>"
" }}}
" ============================================================================
" Plugins {{{
" ============================================================================
call plug#begin(expand('$XDG_DATA_HOME/nvim/plugged'))

" Appearance -----------------------------------------------------------------
Plug 'itchyny/lightline.vim'
Plug 'halkn/tender.vim'
Plug 'sainnhe/edge'
Plug 'sheerun/vim-polyglot'

" Edit -----------------------------------------------------------------------
Plug 'tpope/vim-commentary'
Plug 'machakann/vim-sandwich'
Plug 'cohama/lexima.vim'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace', { 'on' : '<Plug>(operator-replace)' }
Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }

" Dev ------------------------------------------------------------------------
Plug 'mhinz/vim-signify', { 'on': 'SignifyToggle' }
Plug 'tpope/vim-fugitive', {
  \ 'on': ['Git', 'Gcommit', 'Gstatus', 'Gdiff', 'Gblame', 'Glog']
  \ }

if has('nvim')
  Plug 'neovim/nvim-lsp'
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'Shougo/deoplete-lsp'
  Plug 'Shougo/echodoc.vim'
endif
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }

Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }
Plug 'mattn/vim-maketable', { 'for' : 'markdown' }
Plug 'iamcco/markdown-preview.nvim', {
  \ 'do': { -> mkdp#util#install() },
  \ }

" Util -----------------------------------------------------------------------
Plug 'liuchengxu/vim-clap', { 'on': 'Clap' }
Plug 'voldikss/vim-floaterm', { 'on': 'FloatermToggle' }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew','MemoList','MemoGrep'] }

call plug#end()
" }}}
" ============================================================================
" Options {{{
" ============================================================================
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
set cursorline
set wrap
set list
set listchars=tab:\ \ ,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
" set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set showtabline=0
set synmaxcol=512
set showcmd
set signcolumn=yes

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

" help
set helplang=ja,en

" grep
if executable('rg')
  let &grepprg = 'rg --vimgrep --hidden'
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

if has('nvim')
  set inccommand=split
endif
" }}}
" ============================================================================
" Mapping {{{
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
nnoremap ts :<C-u>split <BAR>terminal<CR> <BAR> i
nnoremap tv :<C-u>vsplit <BAR> terminal <CR> <BAR> i
nnoremap tt :<C-u>tabnew <BAR> terminal <CR> <BAR> i
nnoremap tw :<C-u>terminal<CR> <BAR> i

" Use <A-*> to navigate windows
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
tnoremap <A-w> <C-\><C-N><C-w><C-w>
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-w> <C-\><C-N><C-w><C-w>
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
nnoremap <A-w> <C-w><C-w>

" Use ESC to transition to terminal normal mode
"tnoremap <ESC> <C-\><C-n>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>o [Toggle]
nnoremap <silent> [Toggle]n :<C-u>setlocal number! number?<CR>
nnoremap <silent> [Toggle]rn :<C-u>setlocal relativenumber! relativenumber?<CR>
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
" }}}
" ============================================================================
" autocmd {{{
" ============================================================================
augroup vimrc-Filetype
  autocmd!
  autocmd FileType gitcommit setlocal spell spelllang=cjk,en
  autocmd FileType git setlocal nofoldenable
  autocmd FileType text setlocal textwidth=0
  autocmd FileType vim setlocal foldmethod=marker tabstop=2 shiftwidth=2
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2
  autocmd FileType zsh setlocal tabstop=2 shiftwidth=2
  autocmd FileType markdown setlocal tabstop=2 shiftwidth=2
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
augroup END

augroup vimrc-help
  autocmd!
  autocmd FileType help wincmd L
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
augroup END

augroup vimrc-quickfix
  autocmd!
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
augroup END
" }}}
" ============================================================================
" Plugin Config {{{
" ============================================================================

" Appearance -----------------------------------------------------------------
" lightline.vim
let g:lightline = {
  \ 'colorscheme': 'edge',
  \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
  \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
  \ }

" tender
set background=dark
if exists('&termguicolors')
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
silent! colorscheme edge

" Edit -----------------------------------------------------------------------
" vim-commentary
nmap <Leader>c gcc
vmap <Leader>c gc

" vim-operator-replace
map R  <Plug>(operator-replace)

" Dev ------------------------------------------------------------------------

" vim-fugitive
nmap [fugitive] <Nop>
map <Leader>g [fugitive]
nnoremap <silent> [fugitive]s :<C-u>Gstatus<CR>
nnoremap <silent> [fugitive]a :<C-u>Gwrite<CR>
nnoremap <silent> [fugitive]c :<C-u>Gcommit<CR>
nnoremap <silent> [fugitive]d :<C-u>Gdiff<CR>
nnoremap <silent> [fugitive]b :<C-u>Gblame<CR>
nnoremap <silent> [fugitive]l :<C-u>Glog<CR>

" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
let g:signify_vcs_list = [ 'git' ]

" nvim-lsp

lua << EOF
  require'nvim_lsp'.gopls.setup{
    log_level = 0;
    settings = {
      completeUnimported = true;
      usePlaceholders = true;
      staticcheck = true;
    }
  }
EOF
if executable('gopls')
  augroup vimrc-lsp-go
  au!
  autocmd Filetype go setlocal omnifunc=v:lua.vim.lsp.omnifunc
  autocmd BufWritePre *.go :lua vim.lsp.buf.formatting()
  autocmd FileType go call s:setup_lsp()
  augroup END
endif

lua require'nvim_lsp'.bashls.setup{}
if executable('bash-language-server')
  augroup vimrc-lsp-sh
  au!
  autocmd Filetype sh setlocal omnifunc=v:lua.vim.lsp.omnifunc
  autocmd BufWritePre *.sh :lua vim.lsp.buf.formatting()
  autocmd FileType sh call s:setup_lsp()
  augroup END
endif

function! s:setup_lsp() abort
  nnoremap <silent> <buffer> gd    <cmd>lua vim.lsp.buf.definition()<CR>
  nnoremap <silent> <buffer> <C-]> <cmd>lua vim.lsp.buf.definition()<CR>
  nnoremap <silent> <buffer> K     <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> <buffer> gy    <cmd>lua vim.lsp.buf.type_definition()<CR>
  nnoremap <silent> <buffer> gr    <cmd>lua vim.lsp.buf.references()<CR>
  nnoremap <silent> <buffer> <F2>  <cmd>lua vim.lsp.buf.rename()<CR>
endfunction

" Vista
let g:vista_default_executive = 'nvim_lsp'
nnoremap <silent><c-t> :<c-u>Vista!!<CR>
let g:vista#renderer#enable_icon = 0

" deoplete.nvim
let g:deoplete#enable_at_startup = 1

" echodoc
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'floating'

" Go
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

" markdown
let g:markdown_fenced_languages = [
  \ 'go',
  \ 'vim',
  \ 'sh',
  \ ]

augroup vimrc-markdown-preview
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <silent> <Leader>p :<C-u>MarkdownPreview<CR>
augroup END

" vim-table-mode
let g:table_mode_corner = '|'

" Util -----------------------------------------------------------------------

" vim-clap
nnoremap <silent> <Leader>f :<C-u>Clap files --hidden .<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>
nnoremap <silent> <Leader>l :<C-u>Clap blines<CR>
nnoremap <silent> <Leader>G :<C-u>Clap grep --hidden<CR>
nnoremap <silent> <Leader>L :<C-u>Clap<CR>

" vim-floaterm
let g:floaterm_position = 'center'
let g:floaterm_keymap_toggle = '<F12>'
nnoremap <silent> <F12> :<C-u>FloatermToggle<CR>


" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent><C-w>r :<c-u>WinResizerStartResize<CR>

" Calendar.vim
let g:calendar_cache_directory = '$XDG_CACHE_HOME/calendar.vim/.'

" memolist
let g:memolist_fzf = 1
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
nnoremap <Leader>mn  :<C-u>MemoNew<CR>
nnoremap <Leader>ml  :<C-u>MemoList<CR>
nnoremap <Leader>mg  :<C-u>MemoGrep<CR>

" }}}
" ============================================================================
