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
\  'java',
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
set listchars=tab:>-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set synmaxcol=256
set showcmd
set signcolumn=yes
set noshowmode
set showtabline=0
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
set shortmess+=c

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
Plug 'itchyny/lightline.vim'
Plug 'halkn/lightline-lsp'
Plug 'tyru/columnskip.vim'
Plug 'cohama/lexima.vim'
Plug 'tyru/caw.vim'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
" fzf
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" LSP
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'liuchengxu/vista.vim', { 'on': ['Vista!!', 'Vista'] }
" Develop
Plug 'mattn/vim-findroot'
Plug 'skywind3000/asyncrun.vim'
Plug 'janko/vim-test'
Plug 'kana/vim-altr'
" FileType
Plug 'mattn/vim-goaddtags', { 'for': 'go' }
Plug 'dhruvasagar/vim-table-mode', { 'for': 'markdown' }
Plug 'previm/previm', { 'for': 'markdown' }
Plug 'tyru/open-browser.vim', { 'for': 'markdown' }
" Extension
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew', 'MemoList', 'MemoGrep'] }
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 'voldikss/vim-floaterm', { 'on': ['FloatermToggle', 'FloatermNew'] }
Plug 'tyru/capture.vim', { 'on': 'Capture' }
Plug 'mhinz/vim-signify', { 'on': ['SignifyToggle', 'SignifyDiff'] } 
Plug 'rhysd/committia.vim'
Plug 'rhysd/git-messenger.vim', { 'on': '<Plug>(git-messenger)' }
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

" Location List
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
  au!
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
  au!
  autocmd FileType qf setlocal signcolumn=no
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
augroup END

" vim help
augroup vimrc-ft-help
  au!
  autocmd FileType help wincmd L
  autocmd FileType help setlocal signcolumn=no
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
  autocmd FileType help nnoremap <buffer> <CR> <C-]>
  autocmd FileType help nnoremap <buffer> <BS> <C-T>
augroup END

" ============================================================================
" Plugin config
" ============================================================================
" Global ---------------------------------------------------------------------
" vim-equinusocio-material
let g:equinusocio_material_darker = 1
colorscheme equinusocio_material
hi PMenu guibg=#2f2f2f

" lightline
let g:lightline = {
\ 'colorscheme': 'equinusocio_material',
\ 'active': {
\   'right': [ [ 'lsp_errors', 'lsp_warnings', 'lsp_ok', 'lineinfo' ],
\              [ 'percent' ],
\              [ 'fileformat', 'fileencoding', 'filetype' ] ]
\ },
\ 'component_expand': {
\   'lsp_warnings': 'lightline_lsp#warnings',
\   'lsp_errors':   'lightline_lsp#errors',
\   'lsp_ok':       'lightline_lsp#ok',
\ },
\ 'component_type': {
\   'lsp_warnings': 'warning',
\   'lsp_errors':   'error',
\   'lsp_ok':       'middle',
\ },
\ }

" lexima.vim
let g:lexima_nvim_accept_pum_with_enter = 0
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

" fzf ------------------------------------------------------------------------
let g:fzf_command_prefix = 'Fzf'
let g:fzf_preview_window = 'down:60%'
let g:fzf_layout = { 'window': { 'width': 0.95, 'height': 0.9 } }

" files
command! -bang -nargs=? -complete=dir FzfFiles
\ call fzf#vim#files(<q-args>, fzf#vim#with_preview('down:60%', '?'), <bang>0)

" ripgreo
command! -bang -nargs=* FzfRg
\ call fzf#vim#grep(
\   'rg --column --line-number --no-heading --color=always --smart-case --hidden -- '.shellescape(<q-args>),
\   1,
\   fzf#vim#with_preview('down:60%', '?'), <bang>0
\ )

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --hidden --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec, 'down:60%', '?'), a:fullscreen)
endfunction

command! -nargs=* -bang FzfRG call RipgrepFzf(<q-args>, <bang>0)

" git
function! s:sink_git_status(selected) abort
  let l:key=a:selected[0]
  let l:lines=a:selected[1:]

  if l:key == 'ctrl-p'
    execute('FloatermNew git commit')
    return
  endif

 g:floaterm_gitcommit let l:file=split(a:selected[1])[1]
  if l:key == 'ctrl-m'
    execute('edit ' . l:file)
  elseif l:key == 'ctrl-x'
    execute('split ' . l:file)
  elseif l:key == 'ctrl-v'
    execute('vsplit ' . l:file)
  endif

  return
endfunction

function! s:fzf_git_status() abort
  let l:cmd = 'git -c color.status=always -c status.relativePaths=true status --short'
  let l:spec = {
  \ 'source': l:cmd,
  \ 'sink*': function('s:sink_git_status'),
  \ 'options': [
  \   '--ansi',
  \   '--multi',
  \   '--expect=ctrl-m,ctrl-x,ctrl-v,ctrl-p',
  \   '--preview', 'git diff --color=always -- {-1} | delta',
  \   '--bind', 'ctrl-d:preview-page-down,ctrl-u:preview-page-up',
  \   '--bind', 'alt-j:preview-down,alt-k:preview-up',
  \   '--bind', 'alt-s:toggle-sort',
  \   '--bind', '?:toggle-preview',
  \   '--bind', 'space:execute-silent(git add {+-1})+down+reload:' . l:cmd,
  \   '--bind', 'bspace:execute-silent(git reset -q HEAD {+-1})+down+reload:' . l:cmd,
  \ ]
  \ }
  call fzf#run(fzf#wrap(l:spec))
endfunction

command! -bang -nargs=* FzfGStatus call s:fzf_git_status()

nnoremap <silent> <Leader><Leader> :<C-u>FzfHistory<CR>
nnoremap <silent> <Leader>f  :<C-u>FzfFiles<CR>
nnoremap <silent> <Leader>b  :<C-u>FzfBuffers<CR>
nnoremap <silent> <Leader>l  :<C-u>FzfBLines<CR>
nnoremap <silent> <Leader>R  :<C-u>FzfRG<CR>
nnoremap <silent> <Leader>gs :<C-u>FzfGStatus<CR>
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})

augroup vimrc_fzf
  au!
  autocmd FileType fzf tnoremap <buffer> <silent> <Esc> <Esc>
augroup END

" LSP ------------------------------------------------------------------------
" vim-lsp-settings
let g:lsp_settings = {
\ 'gopls': {
\   'workspace_config': { 'gopls':
\     {
\       'hoverKind': 'FullDocumentation',
\       'completeUnimported': v:true,
\       'usePlaceholders': v:true,
\       'staticcheck': v:true,
\     }
\   }
\ },
\ 'efm-langserver': {
\   'disabled': 0,
\   'whitelist': ['go', 'markdown', 'json', 'sh']
\ }
\}

" vim-lsp
let g:lsp_async_completion = 1
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_float_cursor = 0
let g:lsp_virtual_text_enabled = 1
let g:lsp_virtual_text_prefix = " ‣ "
let g:lsp_signs_enabled = 1
let g:lsp_signs_priority = 11
let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '!!'}
let g:lsp_signs_information = {'text': '●'}
let g:lsp_signs_hint = {'text': '▲'}

function! s:setup_lsp() abort
  setlocal omnifunc=lsp#complete
  nmap <silent> <buffer> gd <Plug>(lsp-definition)
  nmap <silent> <buffer> gy <Plug>(lsp-type-definition)
  nmap <silent> <buffer> gr <Plug>(lsp-references)
  nmap <silent> <buffer> K <Plug>(lsp-hover)
  nmap <silent> <buffer> <LocalLeader>k <Plug>(lsp-peek-definition)
  nmap <silent> <buffer> <F2> <Plug>(lsp-rename)
  nmap <silent> <buffer> <LocalLeader>d <plug>(lsp-document-diagnostics)
endfunction

augroup vimrc-lsp-setup
  au!
  " call s:on_lsp_buffer_enabled only for languages that has the server registered.
  autocmd User lsp_buffer_enabled call s:setup_lsp()
  autocmd BufWritePre *.go  call execute('LspDocumentFormatSync') |
    \ call execute('LspCodeActionSync source.organizeImports')
  autocmd BufWrite *.json call execute('LspDocumentFormatSync')
  autocmd BufWrite *.sh call execute('LspDocumentFormatSync')
augroup END

" asyncomplete.vim
let g:asyncomplete_auto_completeopt = 0
inoremap <expr> <C-y> pumvisible() ? asyncomplete#close_popup() : "\<C-y>"
" vim-vsnip
imap <expr><Tab>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : lexima#expand('<LT>Tab>', 'i')
smap <expr><Tab>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : lexima#expand('<LT>Tab>', 'i')
imap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : lexima#expand('<LT>S-Tab>', 'i')
smap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : lexima#expand('<LT>S-Tab>', 'i')
let g:vsnip_snippet_dir = expand(fnamemodify($MYVIMRC, ":h") . '/snippets')

" vim-vsnip-integ
let g:vsnip_integ_config = {
\ 'vim_lsp': v:true,
\ 'vim_lsc': v:false,
\ 'lamp': v:false,
\ 'deoplete_lsp': v:false,
\ 'nvim_lsp': v:false,
\ 'language_client_neovim': v:false,
\ 'asyncomplete': v:true,
\ 'deoplete': v:false,
\ 'mucomplete': v:false,
\ }

" vista.vim
let g:vista_default_executive = 'vim_lsp'
let g:vista_close_on_jump = 1
let g:vista#renderer#enable_icon = 0
let g:vista_fzf_preview = ['down:60%']
let g:vista_echo_cursor_strategy = 'floating_win'
nnoremap <silent> <Leader>vt :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder<CR>

" Develop --------------------------------------------------------------------
" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
noremap <silent> <Leader>gd :SignifyDiff<CR>
let g:signify_disable_by_default = 0

" asyncrun.vim
let g:asyncrun_open = 8
command! -nargs=* Grep AsyncRun -program=grep -strip <f-args>
augroup vimrc_asyncrun
  au!
  autocmd FileType go nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 go run $VIM_RELNAME<CR>
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 sh $VIM_RELNAME<CR>
augroup END

" vim-test
let g:test#preserve_screen = 1
let test#strategy = "asyncrun_background"

augroup vimrc_vim_test
  au!
  autocmd FileType go,vim nnoremap <silent> <buffer> <LocalLeader>t :<C-u>TestLast<CR>
  autocmd FileType go,vim nnoremap <silent> <buffer> TN :<C-u>TestNearest<CR>
  autocmd FileType go,vim nnoremap <silent> <buffer> TF :<C-u>TestFile<CR>
  autocmd FileType go,vim nnoremap <silent> <buffer> TS :<C-u>TestSuite<CR>
  autocmd FileType go,vim nnoremap <silent> <buffer> TL :<C-u>TestLast<CR>
  autocmd FileType go,vim nnoremap <silent> <buffer> TV :<C-u>TestVisit<CR>
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
" vim-markdown
let g:vim_markdown_folding_disabled = 1

" vim-table-mode
let g:table_mode_corner = '|'
let g:table_mode_map_prefix = '<LocalLeader>'

" previm
augroup vimrc_previm
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p :<C-u>PrevimOpen<CR>
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

" undotree
nnoremap <silent> <Leader>u :UndotreeToggle<cr>
let g:undotree_WindowLayout = 2

" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent> <C-w>r :WinResizerStartResize<CR>

" vim-floaterm
let g:floaterm_autoclose = 2
let g:floaterm_width = 0.9
let g:floaterm_height = 0.9
nnoremap <silent> <F7>       :FloatermNew<CR>
tnoremap <silent> <F7>       <C-\><C-n>:FloatermNew<CR>
nnoremap <silent> <F8>       :FloatermPrev<CR>
tnoremap <silent> <F8>       <C-\><C-n>:FloatermPrev<CR>
nnoremap <silent> <F9>       :FloatermNext<CR>
tnoremap <silent> <F9>       <C-\><C-n>:FloatermNext<CR>
nnoremap <silent> <C-t>      :FloatermToggle<CR>
tnoremap <silent> <C-t>      <C-\><C-n>:FloatermToggle<CR>

function s:floatermSettings()
  tnoremap <silent> <buffer> <ESC> <ESC>
endfunction
" 
augroup vimrc_floaterm
  au!
  autocmd FileType floaterm call s:floatermSettings()
augroup END
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
