" ============================================================================
" Init {{{
" ============================================================================
set encoding=utf-8
scriptencoding utf-8

if has('vim_starting')
  " Use vertical bar cursor in Insert mode
  let &t_SI .= "\e[6 q"
  " Use Block cursor in Normal mode
  let &t_EI .= "\e[2 q"
  " Use Underline cursor in Replace mode
  let &t_SR .= "\e[4 q"
endif

" set reader
let mapleader = "\<Space>"

" }}}
" ============================================================================
" Load Plugins {{{
" ============================================================================
call plug#begin('~/.vim/plugged')

" Util -----------------------------------------------------------------------
Plug 'vim-jp/vimdoc-ja'
Plug 'halkn/tender.vim'
Plug 'gruvbox-community/gruvbox'
Plug 'nightsense/snow'
Plug 'itchyny/lightline.vim'
Plug 'ctrlpvim/ctrlp.vim', {
  \ 'on': [ 'CtrlP','CtrlPLine','CtrlPBuffer','CtrlPQuickfix','CtrlPRg' ]
  \ }
Plug 'halkn/ripgrep.vim', { 'on' : [ 'Rg','CtrlPRg' ] }
Plug 'tpope/vim-fugitive', {
  \ 'on': ['Git', 'Gcommit', 'Gstatus', 'Gdiff', 'Gblame', 'Glog']
  \ }

" Edit -----------------------------------------------------------------------
Plug 'tpope/vim-commentary'
Plug 'cohama/lexima.vim'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace', { 'on' : '<Plug>(operator-replace)' }

" Dev ------------------------------------------------------------------------
" lsp
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
" snippet
Plug 'honza/vim-snippets'
Plug 'SirVer/ultisnips'
" autoComplete
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-buffer.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/asyncomplete-ultisnips.vim'
" Runner
Plug 'thinca/vim-quickrun'

" Lang -----------------------------------------------------------------------
" Go
Plug 'fatih/vim-go', {
  \ 'do': ':GoUpdateBinaries',
  \ 'for': [ 'go','gomod' ]
  \ }

" Markdown
Plug 'previm/previm', { 'for' : 'markdown' }
Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }
Plug 'mattn/vim-maketable', { 'for' : 'markdown' }
Plug 'tyru/open-browser.vim', {
  \ 'for': 'markdown',
  \ 'on': '<Plug>(openbrowser-smart-search)'
  \ }

" Other ----------------------------------------------------------------------
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'mhinz/vim-signify', { 'on': 'SignifyToggle' }
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesToggle' }
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew','MemoList','MemoGrep'] }
Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }
Plug 'mattn/sonictemplate-vim', { 'on' : 'Template' }
Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }

call plug#end()

" }}}
" ============================================================================
" mapping {{{
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
tnoremap <silent> <C-q> <C-w>N:q!<CR>

" open termianl in vertial split,new tab,current winddow
nnoremap ts :<C-u>terminal<CR>
nnoremap tv :<C-u>vsplit <BAR> terminal ++curwin<CR>
nnoremap tt :<C-u>tabnew <BAR> terminal ++curwin<CR>
nnoremap tw :<C-u>terminal ++curwin<CR>

" Use ESC to transition to terminal normal mode
tnoremap <ESC> <C-w>N

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
" options {{{
" ============================================================================

" Encoding
set fileencodings=utf-8
set fileformats=unix,dos,mac

" color
set background=dark
if exists('&termguicolors')
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
silent! colorscheme snow
syntax on

" Don't creat swap files
set nobackup
set noswapfile
set noundofile

" Appearance
set wildmenu
set display=lastline
set laststatus=2
set cursorline
" set number
" set relativenumber
set wrap
set list
set listchars=tab:\ \ ,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
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
set clipboard=unnamed

" Completion
set completeopt=popup,menuone,noinsert,noselect

" help
set helplang=ja,en

" vimfinfo
set viminfo+='1000,n$XDG_CACHE_HOME/vim/viminfo

" grep
if executable('rg')
  let &grepprg = 'rg --vimgrep --hidden'
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

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
" Plugin setting {{{
" ============================================================================

" Util {{{

" lightline.vim
let g:lightline = {
  \ 'colorscheme': 'snow_dark',
  \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
  \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
  \ }

" ctrlp.vim
let g:ctrlp_user_command = 'fd --type file --hidden -E .git -E .svn'
let g:ctrlp_use_caching = 1
let g:ctrlp_cache_dir = $XDG_CACHE_HOME.'/ctrlp'
let g:ctrlp_match_window = 'bottom,oreder:ttb,min:1,max:10,results:0'
let g:ctrlp_prompt_mappings = {
  \ 'PrtBS()':            ['<bs>', '<c-]>', '<c-h>'],
  \ 'PrtSelectMove("j")': ['<c-j>', '<down>', '<c-n>'],
  \ 'PrtSelectMove("k")': ['<c-k>', '<up>', '<c-p>'],
  \ 'PrtHistory(-1)':     ['<Nop>'],
  \ 'PrtHistory(1)':      ['<Nop>'],
  \ 'PrtCurLeft()':       ['<left>', '<c-^>'],
  \ }
let g:ctrlp_map = '<Nop>'
nnoremap <silent> <Leader>f :<C-u>CtrlP .<CR>
nnoremap <silent> <Leader>b :<C-u>CtrlPBuffer<CR>
nnoremap <silent> <Leader>l :<C-u>CtrlPLine<CR>
nnoremap <silent> <Leader>q :<C-u>cclose<CR> <BAR> :CtrlPQuickfix<CR>
nnoremap <Leader>R :CtrlPRg<Space>

" vim-fugitive
nmap [fugitive] <Nop>
map <Leader>g [fugitive]
nnoremap <silent> [fugitive]s :<C-u>Gstatus<CR>
nnoremap <silent> [fugitive]a :<C-u>Gwrite<CR>
nnoremap <silent> [fugitive]c :<C-u>Gcommit<CR>
nnoremap <silent> [fugitive]d :<C-u>Gdiff<CR>
nnoremap <silent> [fugitive]b :<C-u>Gblame<CR>
nnoremap <silent> [fugitive]l :<C-u>Glog<CR>

" }}}

" Edit {{{

" vim-commentary
nmap <Leader>c gcc
vmap <Leader>c gc

" vim-operator-replace
map R  <Plug>(operator-replace)

" }}}

" Dev {{{

" LSP {{{

" Enable auto complete
let g:lsp_async_completion = 1

" Enable Document diagnostics
let g:lsp_diagnostics_enabled = 1
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '!!'}
let g:lsp_signs_information = {'text': '●'}
let g:lsp_signs_hint = {'text': '▲'}

" highlight link LspErrorText GruvboxRedSign
highlight clear LspWarningLine

" golang
if executable('gopls')
  augroup vimrc-LspGo
  au!
  autocmd User lsp_setup call lsp#register_server({
    \ 'name': 'gopls',
    \ 'cmd': {server_info->['gopls', '-mode', 'stdio']},
    \ 'whitelist': ['go'],
    \ 'workspace_config': {'gopls': 
    \   {
    \     'hoverKind': 'SynopsisDocumentation',
    \     'completeUnimported': v:true,
    \     'staticcheck': v:true,
    \   }
    \ },
    \ })
  autocmd FileType go call s:setup_lsp()
  augroup END
endif

if executable('pyls')
  augroup vimrc-LspPython
  au!
  autocmd User lsp_setup call lsp#register_server({
    \ 'name': 'pyls',
    \ 'cmd': {server_info->['pyls']},
    \ 'whitelist': ['python'],
    \ 'workspace_config': {'pyls':
    \   {'plugins':
    \     {'pydocstyle': {'enabled': v:true}}
    \   }
    \ }
    \ })
  autocmd FileType python call s:setup_lsp()
  autocmd BufWritePre *.py LspDocumentFormatSync
  augroup END
endif

" bash
if executable('bash-language-server')
  augroup vimrc-LspBash
  au!
  autocmd User lsp_setup call lsp#register_server({
    \ 'name': 'bash-language-server',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'bash-language-server start']},
    \ 'whitelist': ['sh'],
    \ })
  augroup END
endif

" vim
if executable('vim-language-server')
  augroup vimrc-LspVim
  au!
  autocmd User lsp_setup call lsp#register_server({
    \ 'name': 'vim-language-server',
    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'vim-language-server --stdio']},
    \ 'whitelist': ['vim'],
    \ })
  augroup END
endif

" efm ( markdown and vim )
if executable('efm-langserver')
  augroup vimrc-LspEFM
    au!
    autocmd User lsp_setup call lsp#register_server({
      \ 'name': 'efm-langserver-erb',
      \ 'cmd': {server_info->['efm-langserver']},
      \ 'whitelist': ['markdown'],
      \ })
  augroup END
endif

function! s:setup_lsp() abort
  setlocal omnifunc=lsp#complete
  nmap <silent> <buffer> gd <Plug>(lsp-definition)
  nmap <silent> <buffer> gy <Plug>(lsp-type-definition)
  nmap <silent> <buffer> gr <Plug>(lsp-references)
  " nmap <silent> <buffer> gr <Plug>(lsp-next-reference)
  " nmap <silent> <buffer> gR <Plug>(lsp-previous-reference)
  nmap <silent> <buffer> K <Plug>(lsp-hover)
  nmap <silent> <buffer> <Leader>k <Plug>(lsp-peek-definition)
  nmap <silent> <buffer> <F2> <Plug>(lsp-rename)
endfunction

" Debugging
"let g:lsp_log_verbose = 1
"let g:lsp_log_file = expand('~/vim-lsp.log')
" for asyncomplete.vim log
" let g:asyncomplete_log_file = expand('~/asyncomplete.log')

" }}}

" autoComplete {{{

augroup vimrc-AsyncompleteSetup
  " asyncomplete-ultisnips.
  autocmd User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
    \ 'name': 'ultisnips',
    \ 'whitelist': ['*'],
    \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
    \ }))
  " asyncomplete-buffer
  autocmd User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
    \ 'name': 'buffer',
    \ 'whitelist': ['*'],
    \ 'blacklist': ['go','python'],
    \ 'completor': function('asyncomplete#sources#buffer#completor'),
    \ 'config': {
    \  'max_buffer_size': 5000000,
    \  },
    \ }))
augroup END

" }}}

" Runner {{{

" quickrun.vim
let g:quickrun_config = {}
command! -nargs=+ -complete=command Capture QuickRun -type vim -src <q-args>

" }}}

" }}}

" Lang {{{

" Golang {{{
" Use vim-lsp
let g:go_gopls_enabled = 0
let g:go_code_completion_enabled = 0
let g:go_doc_keywordprg_enabled = 0
let g:go_def_mapping_enabled = 0

" hightlight
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

" format
let g:go_fmt_command = 'goimports'

" lint
let g:go_metalinter_autosave = 1
let g:go_metalinter_command = 'golangci-lint'
let g:go_metalinter_autosave_enabled = [ 'golint', 'errcheck']
let g:go_metalinter_enabled = ['golint', 'errcheck']

" list
let g:go_list_type = 'quickfix'

" mapping
augroup vimrc-GoCommads
  autocmd!
  autocmd FileType go nmap <buffer> <silent> <leader>r <Plug>(go-run)
  autocmd FileType go nmap <buffer> <silent> <leader>t <Plug>(go-test)
  autocmd FileType go nmap <buffer> <silent> <leader>v <Plug>(go-coverage-toggle)
  autocmd FileType go nmap <buffer> <silent> <Leader>ie <Plug>(go-iferr)
  autocmd FileType go nmap <buffer> <silent> <Leader>im <Plug>(go-implements)
  autocmd FileType go nmap <buffer> <silent> <Leader>dl :<C-u>GoDecls<CR>
  autocmd FileType go nmap <buffer> <silent> <Leader>dd :<C-u>GoDeclsDir<CR>

  autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
  autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
  autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
  autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
augroup END

" }}}

" Marldown {{{

" markdown
let g:markdown_fenced_languages = [
  \ 'go',
  \ 'python',
  \ 'vim',
  \ 'sh',
  \ ]

" previm
let g:previm_disable_default_css = 1
let g:previm_custom_css_path = '$HOME/.dotfiles/etc/templates/previm/markdown.css'
augroup vimrc-Previm
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <silent> <Leader>p :<C-u>PrevimOpen<CR>
  autocmd FileType markdown nnoremap <buffer> <silent> <Leader>r :<C-u>call previm#refresh()<CR>
augroup END

" vim-table-mode
let g:table_mode_corner = '|'

" open-browser
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)

" }}}

" }}}

" Other {{{

" nerdtree
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.git$', '\.svn$', '\~$']
nmap <silent><c-e> :<c-u>NERDTreeToggle<CR>

" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
let g:signify_vcs_list = [ 'git' ]

" indentLine
let g:loaded_indentLine = 1
nnoremap <silent><c-d> :<c-u>IndentLinesToggle<CR>

" vim-ripgrep
let g:rg_command = 'rg --vimgrep --hidden --glob "!{.git,.svn}"'
let g:rg_format = '%f:%l:%c:%m,%f:%l:%m'

" vista.vim
let g:vista_default_executive = 'vim_lsp'
nnoremap <silent><c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder vim_lsp<CR>
let g:vista#renderer#enable_icon = 0

" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent><C-w>r :<c-u>WinResizerStartResize<CR>

" memolist
let g:memolist_ex_cmd = 'CtrlP'
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
nnoremap <Leader>mn  :<C-u>MemoNew<CR>
nnoremap <Leader>ml  :<C-u>MemoList<CR>
nnoremap <Leader>mg  :<C-u>MemoGrep<CR>

" vim-easy-align
vmap <Enter> <Plug>(EasyAlign)

" }}}

" }}}
" ============================================================================
