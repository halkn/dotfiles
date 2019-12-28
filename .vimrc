" ============================================================================
" Init {{{
" ============================================================================
set encoding=utf-8
scriptencoding utf-8

syntax enable
filetype plugin indent on

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
augroup vimrc-ft-indent
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
" Plugin {{{
" Plugin Manager {{{

" Plugin list {{{
" start_layout
let s:start_layout_plugs = [
  \ ['halkn/tender.vim', {'type': 'opt'}],
  \ ['sainnhe/edge', {}],
  \ ['itchyny/lightline.vim', {}],
  \ ['vim-jp/vimdoc-ja', {}],
  \ ['sheerun/vim-polyglot', {}],
  \ ]
" start_edit
let s:start_edit_plugs = [
  \ ['cohama/lexima.vim', {}],
  \ ['tpope/vim-commentary', {}],
  \ ['kana/vim-operator-user', {}],
  \ ['kana/vim-operator-replace', {}],
  \ ['machakann/vim-sandwich', {}],
  \ ['junegunn/vim-easy-align', {}],
  \ ]
" start_util
let s:start_util_plugs = [
  \ ['liuchengxu/vim-clap', {}], 
  \ ['tpope/vim-fugitive', {}],
  \ ['mhinz/vim-signify', {}],
  \ ['simeji/winresizer', {}],
  \ ['tyru/open-browser.vim', {}],
  \ ['itchyny/calendar.vim', {}],
  \ ['glidenote/memolist.vim', {}],
  \ ]
" start_lsp
let s:start_lsp_plugs = [
  \ ['prabirshrestha/async.vim', {}],
  \ ['prabirshrestha/vim-lsp', {}],
  \ ['prabirshrestha/asyncomplete.vim', {}],
  \ ['prabirshrestha/asyncomplete-buffer.vim', {}],
  \ ['prabirshrestha/asyncomplete-lsp.vim', {}],
  \ ]
" opt_dev
let s:opt_plugs_dev = [
  \ ['Shougo/echodoc.vim', {'type': 'opt'}],
  \ ['liuchengxu/vista.vim', {'type': 'opt'}],
  \ ['mattn/sonictemplate-vim', {'type': 'opt'}],
  \ ['thinca/vim-quickrun', {'type': 'opt'}],
  \ ['janko/vim-test', {'type': 'opt'}],
  \ ]
" opt_go
let s:opt_plugs_go = [
  \ ['mattn/vim-goimports', {'type': 'opt'}],
  \ ['arp242/switchy.vim', {'type': 'opt'}],
  \ ]
" opt_markdown
let s:opt_plugs_markdown = [
  \ ['previm/previm', {'type': 'opt'}],
  \ ['dhruvasagar/vim-table-mode', {'type': 'opt'}],
  \ ['mattn/vim-maketable', {'type': 'opt'}],
  \ ]
" }}}

if exists('*minpac#init')
  " load minpac.
  call minpac#init()
  call minpac#add('k-takata/minpac', {'type': 'opt'})

  " function to load plugin.
  function! s:minpac_add(plugs)
    for l:plug in a:plugs
      exe 'call minpac#add("' . l:plug[0] . '", ' . string(l:plug[1]) . ')'
    endfor
  endfunction

  " load plugins
  call s:minpac_add(s:start_layout_plugs)
  call s:minpac_add(s:start_edit_plugs)
  call s:minpac_add(s:start_util_plugs)
  call s:minpac_add(s:start_lsp_plugs)
  call s:minpac_add(s:opt_plugs_dev)
  call s:minpac_add(s:opt_plugs_go)
  call s:minpac_add(s:opt_plugs_markdown)
endif

" Define user commands for updating/cleaning the plugins.
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update('', {'do': 'call minpac#status()'})
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()
command! PackStatus packadd minpac | source $MYVIMRC | call minpac#status()

" Lazy load
function! s:plug_lazyload(plugs)
  for l:plug in a:plugs
    let l:name = split(l:plug[0], '/')[1]
    exe 'packadd ' . l:name
  endfor
endfunction

function! s:plug_load_dev() abort
  if exists('g:vimrc_loaded_dev_plug')
    return
  endif
  let g:vimrc_loaded_dev_plug = 1
  call s:plug_lazyload(s:opt_plugs_dev)
endfunction

augroup vimrc-ft-plugin
  au!
  autocmd FileType sh,go,python call s:plug_load_dev()
  autocmd BufNew,BufRead *.go ++once call s:plug_lazyload(s:opt_plugs_go)
  autocmd FileType markdown ++once call s:plug_lazyload(s:opt_plugs_markdown)
augroup END

" }}}

" Plugin setting {{{

" layout {{{
" tender
set background=dark
if exists('&termguicolors')
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
let g:edge_disable_italic_comment = 1
silent! colorscheme edge

" lightline.vim
let g:lightline = {
  \ 'colorscheme': 'edge',
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
" }}}

" edit {{{
" vim-commentary
nmap <Leader>c gcc
vmap <Leader>c gc

" vim-operator-replace
map R  <Plug>(operator-replace)

" vim-easy-align
vmap <Enter> <Plug>(EasyAlign)
" }}}

" util {{{
" vim-clap
let g:clap_default_external_filter = 'fzf'
nnoremap <silent> <Leader>f :<C-u>Clap files --hidden<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>
nnoremap <silent> <Leader>l :<C-u>Clap blines<CR>
nnoremap <silent> <Leader>G :<C-u>Clap grep --hidden<CR>
nnoremap <silent> <Leader>q :<C-u>Clap quickfix<CR>
nnoremap <silent> <Leader>L :<C-u>Clap<CR>

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

" winresizer
let g:winresizer_start_key = '<C-w>r'

" open-browser
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)

" calender.vim
let g:calendar_cache_directory = expand('$XDG_CACHE_HOME/calendar.vim')

" memolist
let g:memolist_path = expand('~/memo')
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
nnoremap <Leader>mn :<C-u>MemoNew<CR>
nnoremap <Leader>mg :<C-u>MemoGrep<CR>
nnoremap <Leader>ml :<C-u>Clap memo<CR>

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

" }}}

" lsp {{{
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
  " autocmd FileType go call s:setup_lsp()
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
  " autocmd FileType python call s:setup_lsp()
  " autocmd BufWritePre *.py LspDocumentFormatSync
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
  " autocmd FileType sh call s:setup_lsp()
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
  " autocmd FileType vim call s:setup_lsp()
  augroup END
endif

" efm ( markdown )
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

augroup vimrc-lsp-install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:setup_lsp()
augroup END

" Debugging
"let g:lsp_log_verbose = 1
"let g:lsp_log_file = expand('~/vim-lsp.log')
" for asyncomplete.vim log
" let g:asyncomplete_log_file = expand('~/asyncomplete.log')

" asyncomplete.vim
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

" opt_dev {{{
" echodoc
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'popup'
highlight link EchoDocPopup Pmenu

" vista.vim
let g:vista_default_executive = 'vim_lsp'
nnoremap <silent><c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder vim_lsp<CR>
let g:vista#renderer#enable_icon = 0

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

" opt_go {{{
augroup vimrc-GoCommands
  au!
  autocmd FileType go nnoremap <buffer> <silent> <Leader>a :<C-u>call switchy#switch('edit', 'buf')<CR>
  autocmd Filetype go command! -bang A call switchy#switch('edit', 'buf')
  autocmd Filetype go command! -bang AS call switchy#switch('split', 'sbuf')
augroup END
" }}}

" opt_markdown {{{
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
" }}}

" }}}

" }}}
" ============================================================================
