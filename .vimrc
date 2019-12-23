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
" call plug#begin('~/.vim/plugged')

" " Util -----------------------------------------------------------------------
" Plug 'vim-jp/vimdoc-ja'
" Plug 'halkn/tender.vim'
" Plug 'itchyny/lightline.vim'
" Plug 'sheerun/vim-polyglot'
" Plug 'liuchengxu/vim-clap', { 'on': 'Clap' }
" Plug 'tpope/vim-fugitive', {
"   \ 'on': ['Git', 'Gcommit', 'Gstatus', 'Gdiff', 'Gblame', 'Glog']
"   \ }

" " Edit -----------------------------------------------------------------------
" Plug 'tpope/vim-commentary'
" Plug 'cohama/lexima.vim'
" Plug 'machakann/vim-sandwich'
" Plug 'Shougo/echodoc.vim'
" Plug 'kana/vim-operator-user'
" Plug 'kana/vim-operator-replace', { 'on' : '<Plug>(operator-replace)' }

" " Dev ------------------------------------------------------------------------
" " lsp
" Plug 'prabirshrestha/async.vim'
" Plug 'prabirshrestha/vim-lsp'
" " snippet
" Plug 'mattn/sonictemplate-vim'
" " autoComplete
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-buffer.vim'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'
" " Runner
" Plug 'thinca/vim-quickrun'
" Plug 'janko/vim-test'

" " Lang -----------------------------------------------------------------------
" " Go
" Plug 'mattn/vim-goimports', { 'for': [ 'go','gomod' ] }
" Plug 'arp242/switchy.vim', { 'for': 'go' }

" " Markdown
" Plug 'previm/previm', { 'for' : 'markdown' }
" Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }
" Plug 'mattn/vim-maketable', { 'for' : 'markdown' }
" Plug 'tyru/open-browser.vim', {
"   \ 'for': 'markdown',
"   \ 'on': '<Plug>(openbrowser-smart-search)'
"   \ }

" " Other ----------------------------------------------------------------------
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" Plug 'mhinz/vim-signify', { 'on': 'SignifyToggle' }
" Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesToggle' }
" Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }
" Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
" Plug 'glidenote/memolist.vim', { 'on': ['MemoNew','MemoList','MemoGrep'] }
" Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }
" Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }

" call plug#end()

" }}}
" ============================================================================
" Plugin {{{

" start_plugs {{{
let s:start_plugs = [
  \ ['halkn/tender.vim', {}],
  \ ['itchyny/lightline.vim', {}],
  \ ['sheerun/vim-polyglot', {}],
  \ ['liuchengxu/vim-clap', {}], 
  \ ['prabirshrestha/async.vim', {}],
  \ ['prabirshrestha/vim-lsp', {}],
  \ ]
" }}}

" opt_plugs_lazy {{{
let s:opt_plugs_lazy = [
  \ ['tpope/vim-fugitive', {'type': 'opt'}],
  \ ['mhinz/vim-signify', {'type': 'opt'}],
  \ ['prabirshrestha/asyncomplete.vim', {'type': 'opt'}],
  \ ['prabirshrestha/asyncomplete-buffer.vim', {'type': 'opt'}],
  \ ['prabirshrestha/asyncomplete-lsp.vim', {'type': 'opt'}],
  \ ['cohama/lexima.vim', {'type': 'opt'}],
  \ ['tpope/vim-commentary', {'type': 'opt'}],
  \ ['junegunn/vim-easy-align', {'type': 'opt'}],
  \ ['machakann/vim-sandwich', {'type': 'opt'}],
  \ ['kana/vim-operator-user', {'type': 'opt'}],
  \ ['kana/vim-operator-replace', {'type': 'opt'}],
  \ ['simeji/winresizer', {'type': 'opt'}],
  \ ['glidenote/memolist.vim', {'type': 'opt'}],
  \ ['itchyny/calendar.vim', {'type': 'opt'}],
  \ ['tyru/open-browser.vim', {'type': 'opt'}],
  \ ['vim-jp/vimdoc-ja', {'type': 'opt'}],
  \ ]
" }}}

" opt_plugs_dev {{{
let s:opt_plugs_dev = [
  \ ['Shougo/echodoc.vim', {'type': 'opt'}],
  \ ['liuchengxu/vista.vim', {'type': 'opt'}],
  \ ['mattn/sonictemplate-vim', {'type': 'opt'}],
  \ ['thinca/vim-quickrun', {'type': 'opt'}],
  \ ['janko/vim-test', {'type': 'opt'}],
  \ ]
" }}}

" opt_plugs_go {{{
let s:opt_plugs_go = [
  \ ['mattn/vim-goimports', {'type': 'opt'}],
  \ ['arp242/switchy.vim', {'type': 'opt'}],
  \ ]
" }}}

" opt_plugs_markdown {{{
let s:opt_plugs_markdown = [
  \ ['previm/previm', {'type': 'opt'}],
  \ ['dhruvasagar/vim-table-mode', {'type': 'opt'}],
  \ ['mattn/vim-maketable', {'type': 'opt'}],
  \ ]
" }}}

if exists('*minpac#init')

  " load minpac.
  packadd minpac call minpac#init()
  call minpac#add('k-takata/minpac', {'type': 'opt'})

  " load other plugins.
  function! s:minpac_add(plugs)
    for l:plug in a:plugs
      exe 'call minpac#add("' . l:plug[0] . '", ' . string(l:plug[1]) . ')'
    endfor
  endfunction

  call s:minpac_add(s:start_plugs)
  call s:minpac_add(s:opt_plugs_lazy)
  call s:minpac_add(s:opt_plugs_dev)
  call s:minpac_add(s:opt_plugs_go)
  call s:minpac_add(s:opt_plugs_markdown)

endif

" packloadall
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update('', {'do': 'call minpac#status()'})
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()
command! PackStatus packadd minpac | source $MYVIMRC | call minpac#status()

function! s:minpac_lazy(plugs)
  for l:plug in a:plugs
    let l:name = split(l:plug[0], '/')[1]
    exe 'packadd ' . l:name
  endfor
endfunction

function! LazyLoad(timer)
  for l:plug in s:opt_plugs_lazy
    let l:name = split(l:plug[0], '/')[1]
    exe 'packadd ' . l:name
  endfor
endfunction

augroup lazy_load_bundle
  au!
  autocmd VimEnter * call timer_start(1, 'LazyLoad')
augroup END

augroup vimrc-ft-plugin
  autocmd!
  autocmd FileType sh,go,python call s:minpac_lazy(s:opt_plugs_dev)
  autocmd BufNew,BufRead *.go call s:minpac_lazy(s:opt_plugs_go)
  autocmd FileType markdown call s:minpac_lazy(s:opt_plugs_markdown)
augroup END

syntax enable
filetype plugin indent on

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

" Use <C-w>ESC to transition to terminal normal mode
tnoremap <C-w><ESC> <C-w>N

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
set fileencodings=utf-8,cp932
set fileformats=unix,dos,mac

" color
set background=dark
if exists('&termguicolors')
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
silent! colorscheme tender

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
set listchars=tab:>-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set synmaxcol=256
set showcmd
set signcolumn=yes
set noshowmode
if has("gui_running")
  set showtabline=2
else
  set showtabline=0
endif

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
  \ 'colorscheme': 'wombat',
  \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
  \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
  \ }

" vim-polyglot
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

" vim-clap
let g:clap_default_external_filter = 'fzf'
nnoremap <silent> <Leader>f :<C-u>Clap files --hidden<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>
nnoremap <silent> <Leader>l :<C-u>Clap blines<CR>
nnoremap <silent> <Leader>G :<C-u>Clap grep --hidden<CR>
nnoremap <silent> <Leader>q :<C-u>Clap quickfix<CR>

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

" echodoc
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'popup'
highlight link EchoDocPopup Pmenu

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

" Disable Signature help
let g:lsp_signature_help_enabled = 0

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
    \     'usePlaceholders': v:true,
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
  autocmd FileType sh call s:setup_lsp()
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
  autocmd FileType vim call s:setup_lsp()
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

let g:asyncomplete_auto_completeopt = 0
augroup vimrc-AsyncompleteSetup
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
let g:quickrun_config = {
    \ '_' : {
        \ 'runner' : 'job',
        \ 'outputter' : 'error',
        \ 'outputter/error/success' : 'buffer',
        \ 'outputter/error/error'   : 'quickfix',
    \ }
\}

command! -nargs=+ -complete=command Capture packadd vim-quickrun | QuickRun -type vim -src <q-args>

" vim-test
let g:test#preserve_screen = 1
let test#strategy = "make_bang"

augroup vimrc-TestCommand
  au!
  autocmd FileType go call s:setup_test_command()
augroup END

function! s:setup_test_command() abort
  nnoremap <silent> <buffer> <Leader>t :<C-u>TestFile<CR>
  nnoremap <silent> <buffer> TN :<C-u>TestNearest<CR>
  nnoremap <silent> <buffer> TF :<C-u>TestFile<CR>
  nnoremap <silent> <buffer> TS :<C-u>TestSuite<CR>
  nnoremap <silent> <buffer> TL :<C-u>TestLast<CR>
  nnoremap <silent> <buffer> TV :<C-u>TestVisit<CR>
endfunction

" }}}

" }}}

" Lang {{{

" Golang {{{
 
augroup vimrc-GoCommands
  au!
  autocmd FileType go nnoremap <buffer> <silent> <Leader>a :<C-u>call switchy#switch('edit', 'buf')<CR>
  autocmd Filetype go command! -bang A call switchy#switch('edit', 'buf')
  autocmd Filetype go command! -bang AS call switchy#switch('split', 'sbuf')
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

" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
let g:signify_vcs_list = [ 'git' ]

" vista.vim
let g:vista_default_executive = 'vim_lsp'
nnoremap <silent><c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder vim_lsp<CR>
let g:vista#renderer#enable_icon = 0

" winresizer
let g:winresizer_start_key = '<C-w>r'

" memolist
let g:memolist_path = expand('~/memo')
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
nnoremap <Leader>mn  :<C-u>MemoNew<CR>
nnoremap <Leader>mg  :<C-u>MemoGrep<CR>

" clap-providor for memolit
function! s:find_memo() abort
  let l:memos = substitute(expand(g:memolist_path.'/*.md'), expand(g:memolist_path."/"), "", "g")
  return split(l:memos, "\n")
endfunction

function! s:open_memo(selected) abort
  execute ":edit ".expand(g:memolist_path.'/'.a:selected)
endfunction

let g:clap_provider_memo = {
  \ 'source': function('s:find_memo') ,
  \ 'sink': function('s:open_memo'),
  \ }

nnoremap <Leader>ml :<C-u>Clap memo<CR>

" vim-easy-align
vmap <Enter> <Plug>(EasyAlign)

" }}}

" }}}
" ============================================================================
