" ============================================================================
"  encoding
" ============================================================================
set encoding=utf-8
scriptencoding utf-8

" ============================================================================
"  vim-plug
" ============================================================================
call plug#begin('~/.local/share/nvim/plugged')
 
" Util
Plug 'chriskempson/base16-vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'vim-jp/vimdoc-ja'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesToggle' }
Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }

" Edit
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tyru/caw.vim'
Plug 'cohama/lexima.vim'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive', { 'on': ['Git', 'Gcommit', 'Gstatus', 'Gdiff', 'Gblame', 'Glog'] }

" Development
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

" Document
Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }

call plug#end()

" ============================================================================
" filetype
" ============================================================================
augroup vimrc_filetype
    autocmd!
    autocmd FileType gitcommit setlocal spell spelllang=cjk,en
    autocmd FileType text      setlocal textwidth=0
augroup END

" ============================================================================
" mapping
" ============================================================================
" set reader
let mapleader = "\<Space>"

" reload vimrc
nnoremap <Leader>s :<C-u>source $XDG_CONFIG_HOME/nvim/init.vim<CR>

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

" Resize window
noremap <C-w>> 10<C-w>>
noremap <C-w>< 10<C-w><
noremap <C-w>+ 10<C-w>+
noremap <C-w>- 10<C-w>-

" Not yank is delete operation
nnoremap x "_x

" ============================================================================
" options 
" ============================================================================

" Encoding
set fileencodings=utf-8
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
set number
set relativenumber
set wrap
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set showtabline=2
set synmaxcol=512
set showcmd

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
set virtualedit=block
set virtualedit=onemore
set whichwrap=b,s,[,],<,>
set backspace=indent,eol,start
set inccommand=split

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
set clipboard+=unnamedplus

" Completion
set completeopt=menu,menuone,noinsert,noselect
set wildoptions=pum
set pumblend=20

" help
set helplang=ja,en

" ============================================================================
" Plugin setting
" ============================================================================

" lightline 

let g:lightline = {
    \ 'colorscheme': 'wombat',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ]
    \ },
    \ 'component_function': {
    \   'cocstatus': 'coc#status'
    \ },
    \ }

" fzf
nnoremap <silent> <Leader>f :<C-u>Files<CR>
nnoremap <silent> <Leader>G :<C-u>GFiles?<CR>
nnoremap <silent> <Leader>b :<C-u>Buffers<CR>
nnoremap <silent> <Leader>R :<C-u>Rg<CR>
nnoremap <silent> <Leader>l :<C-u>Lines<CR>
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \ 'rg --column --line-number --hidden --ignore-case --no-heading --color=always '.shellescape(<q-args>), 1,
    \ <bang>0   ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
    \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%:hidden', 'p'),
    \ <bang>0)

" nerdtree
let NERDTreeShowHidden=1
nmap <silent><c-e> :<c-u>NERDTreeToggle<CR>

" indentLine
let g:loaded_indentLine = 1
nnoremap <silent><c-d> :<c-u>IndentLinesToggle<CR>

" vim-easy-align
vmap <Enter> <Plug>(EasyAlign)

" caw.vim
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)
nmap <Leader>, <Plug>(caw:zeropos:toggle)
vmap <Leader>, <Plug>(caw:zeropos:toggle)

" vim-gitgutter
let g:gitgutter_map_keys = 0
map [g <Plug>GitGutterPrevHunk
nmap ]g <Plug>GitGutterNextHunk

" fugitive
nmap [fugitive] <Nop>
map <Leader>g [fugitive]
nnoremap <silent> [fugitive]c :<C-u>Gcommit<CR>
nnoremap <silent> [fugitive]d :<C-u>Gdiff<CR>
nnoremap <silent> [fugitive]b :<C-u>Gblame<CR>
nnoremap <silent> [fugitive]l :<C-u>Glog<CR>

" ============================================================================
" color
" ============================================================================
filetype plugin indent on
syntax on
set background=dark
colorscheme base16-default-dark

if exists('&termguicolors')
    set termguicolors
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

