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
Plug 'harkNK/tender.vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'vim-jp/vimdoc-ja'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesToggle' }
Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }

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
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }

" Document
Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }

call plug#end()

" ============================================================================
" autocmd
" ============================================================================
augroup vimrc_filetype
    autocmd!
    autocmd FileType gitcommit setlocal spell spelllang=cjk,en
    autocmd FileType text      setlocal textwidth=0
augroup END

augroup term_conf
    autocmd!
    autocmd TermOpen * startinsert
    autocmd TermOpen * setlocal norelativenumber
    autocmd TermOpen * setlocal nonumber
    autocmd WinEnter * if &buftype ==# 'terminal' | startinsert | endif
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

" Move cursor the begining and end of line
nnoremap H ^
nnoremap L $
vnoremap H ^
vnoremap L $

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
cnoremap <C-d> <DEL>

" Not yank is delete operation
nnoremap x "_x
nnoremap s "_x

" Use Alt key to move between winddow
nnoremap <A-w> <C-w>w
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
inoremap <A-w> <C-\><C-N><C-w>w
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
tnoremap <A-w> <C-\><C-N><C-w>w
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l

" open termianl in vertial split,new tab,current winddow
nnoremap <silent> ts :<C-u>split <BAR> terminal<CR>
nnoremap <silent> tv :<C-u>vsplit <BAR> terminal<CR>
nnoremap <silent> tt :<C-u>tabnew <BAR> terminal<CR>

" Use <Esc> to change from terminal-Job mode to terminal-Normal mode
tnoremap <Esc> <C-\><C-n>

" Quit the current window
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <Esc>:q<CR>
tnoremap <silent> <C-q> <C-\><C-n>:q<CR>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>t [Toggle]
nnoremap <silent> [Toggle]n :<C-u>setlocal relativenumber! relativenumber?<CR>
nnoremap <silent> [Toggle]w :<C-u>setlocal wrap! wrap?<CR>
nnoremap <silent> [Toggle]p :<C-u>set paste! paste?<CR>

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
set helplang=en,ja

" ============================================================================
" Plugin setting
" ============================================================================

" ============================================================================
" lightline 
" ============================================================================
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

" ============================================================================
" fzf.vim 
" ============================================================================

" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Use floating window
let g:fzf_layout = { 'window': 'call FloatingFZF()' }
function! FloatingFZF()
  let buf = nvim_create_buf(v:false, v:true)
  call setbufvar(buf, 'number', 'no')

  let height = float2nr(&lines/2)
  let width = float2nr(&columns - (&columns * 2 / 10))
  "let width = &columns
  let row = float2nr(&lines / 3)
  let col = float2nr((&columns - width) / 3)

  let opts = {
        \ 'relative': 'editor',
        \ 'row': row,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height,
        \ }
  let win =  nvim_open_win(buf, v:true, opts)
  call setwinvar(win, '&number', 0)
  call setwinvar(win, '&relativenumber', 0)
endfunction

" Override Files command
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

" Override Rg command
let g:rg_command = '
    \ rg --column --line-number --hidden --ignore-case --no-heading  --color "always"
    \ -g "!{.git,.svn,node_modules,vendor}/*" '
command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \ g:rg_command .shellescape(<q-args>), 1,
    \ <bang>0   ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
    \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%:hidden', 'p'),
    \ <bang>0)

" Override Colors command
command! -bang Colors
  \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

" Key mapping
nnoremap <silent> <Leader>f :<C-u>Files<CR>
nnoremap <silent> <Leader>G :<C-u>GFiles?<CR>
nnoremap <silent> <Leader>b :<C-u>Buffers<CR>
nnoremap <silent> <Leader>R :<C-u>Rg<CR>
nnoremap <silent> <Leader>l :<C-u>BLines<CR>
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)

" autocmd
augroup fzf
    autocmd!
    autocmd FileType fzf tnoremap <buffer> <Esc> <C-\><C-n>:q<CR>
augroup END

" ============================================================================
" nerdtree
" ============================================================================
let NERDTreeShowHidden=1
nmap <silent><c-e> :<c-u>NERDTreeToggle<CR>

" ============================================================================
" indentLine
" ============================================================================
let g:loaded_indentLine = 1
nnoremap <silent><c-d> :<c-u>IndentLinesToggle<CR>

" ============================================================================
" vim-easy-align
" ============================================================================
vmap <Enter> <Plug>(EasyAlign)

" ============================================================================
" winresizer.vim
" ============================================================================
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent><C-w>r :<c-u>WinResizerStartResize<CR>

" ============================================================================
" caw.vim
" ============================================================================
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)
nmap <Leader>, <Plug>(caw:zeropos:toggle)
vmap <Leader>, <Plug>(caw:zeropos:toggle)

" ============================================================================
" vim-gitgutter
" ============================================================================
let g:gitgutter_map_keys = 0
map [g <Plug>GitGutterPrevHunk
nmap ]g <Plug>GitGutterNextHunk

" ============================================================================
" fugitive
" ============================================================================
nmap [fugitive] <Nop>
map <Leader>g [fugitive]
nnoremap <silent> [fugitive]c :<C-u>Gcommit<CR>
nnoremap <silent> [fugitive]d :<C-u>Gdiff<CR>
nnoremap <silent> [fugitive]b :<C-u>Gblame<CR>
nnoremap <silent> [fugitive]l :<C-u>Glog<CR>

" ============================================================================
" vim-polyglot
" ============================================================================
" golang
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

" ============================================================================
" Coc.nvim
" ============================================================================
" options
set cmdheight=2
set updatetime=300
set shortmess+=c

" Key mapping
inoremap <silent><expr> <C-space> coc#refresh()
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <F2> <Plug>(coc-rename)
nmap <Leader>m <Plug>(coc-format)
nmap <Leader>ac  <Plug>(coc-codeaction)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Using CocList
nnoremap <silent> <Leader>L :<C-u>CocList<CR>
nnoremap <silent> <Leader>d :<C-u>CocList diagnostics<cr>
nnoremap <silent> <Leader>o :<C-u>CocList outline<cr>

" ============================================================================
" vista
" ============================================================================
let g:vista_default_executive = 'coc'
nnoremap <silent><c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder<CR>
let g:vista#renderer#enable_icon = 0

" ============================================================================
" Plugin setting end
" ============================================================================

" ============================================================================
" color
" ============================================================================
filetype plugin indent on
syntax on
set background=dark
colorscheme tender

if exists('&termguicolors')
    set termguicolors
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

