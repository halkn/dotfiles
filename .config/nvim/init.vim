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
" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8,cp932
set fileformats=unix,dos,mac

" Appearance
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
set termguicolors
set diffopt^=vertical
set shortmess+=c
set shortmess-=S
set helplang=ja,en

" edit
set smarttab
set expandtab
set autoindent
set shiftwidth=2
set shiftround
set tabstop=2
set virtualedit=block,onemore
set whichwrap=b,s,[,],<,>
set backspace=indent,eol,start

" buffer
set hidden
set switchbuf=useopen

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

" performance
set updatetime=300
set ttimeoutlen=10
set lazyredraw

" Completion
set completeopt=menuone,noinsert,noselect
set pumheight=10

" cmdline
set wildmenu 
set wildmode=full
set wildchar=<Tab>

" data files
set nobackup
set noswapfile
set undofile

" clipborad
if has('clipboard')
  set clipboard=unnamedplus
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
nnoremap <Leader>s <cmd>source $MYVIMRC<CR>

" Clear search highlight
nnoremap <Esc><Esc> <cmd>nohlsearch<CR><Esc>
nnoremap <C-l>      <cmd>nohlsearch<CR><C-l>

" Multi line move
noremap k gk
noremap j gj
noremap gk k
noremap gj j

" Move cursor like emacs in Insert Mode
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-a> <C-o>^
inoremap <C-e> <End>
inoremap <C-d> <Del>
imap     <C-h> <BS>

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

" resize window
nnoremap <Left>  5<C-w><
nnoremap <Right> 5<C-w>>
nnoremap <Up>    2<C-w>-
nnoremap <Down>  2<C-w>+

" Quit the current window
nnoremap <C-q> <cmd>q<CR>
inoremap <C-q> <cmd>q<CR><Esc>
tnoremap <C-q> <cmd>q!<CR>

" Not yank is delete operation
nnoremap x "_x
xnoremap x "_x
nnoremap X "_X
xnoremap X "_X

" Yank EOF
nnoremap Y y$

" Does not move when using *
nnoremap * *N

" Indent in visual and select mode automatically re-selects.
vnoremap > >gv
vnoremap < <gv

" Disable dangerous key
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>o [Toggle]
nnoremap [Toggle]n  <cmd>setlocal number! number?<CR>
nnoremap [Toggle]rn <cmd>setlocal relativenumber! relativenumber?<CR>
nnoremap [Toggle]c  <cmd>setlocal cursorline! cursorcolumn!<CR>
nnoremap [Toggle]w  <cmd>setlocal wrap! wrap?<CR>
nnoremap [Toggle]p  <cmd>set paste! paste?<CR>

" terminal
nnoremap <Leader>ts <cmd>split  term://$SHELL<CR>
nnoremap <Leader>tv <cmd>vsplit term://$SHELL<CR>
nnoremap <Leader>tt <cmd>tabnew term://$SHELL<CR>
nnoremap <Leader>tw <cmd>terminal<CR>
tnoremap <silent> <Esc> <C-\><C-n>
function s:ToggleTerminal()
  let l:bufferNum = bufnr('ToggleTerminal')
  if l:bufferNum == -1 || bufloaded(l:bufferNum) != 1
    silent! split term://$SHELL
    file ToggleTerminal
  else
    let l:windowNum = bufwinnr(l:bufferNum)
    if l:windowNum == -1
      silent! execute 'bel sbuffer '.l:bufferNum
      startinsert
    else
      silent! execute l:windowNum.'wincmd w'
      hide
    endif
  endif
endfunction
nnoremap <C-t> <cmd>call <SID>ToggleTerminal()<CR>
tnoremap <C-t> <cmd>call <SID>ToggleTerminal()<CR>

" quickfix/loclist
nnoremap [q <cmd>cprev<CR>
nnoremap ]q <cmd>cnext<CR>
nnoremap [l <cmd>lprevious<CR>
nnoremap ]l <cmd>lnext<CR>
function s:toggleqf() abort
  let l:qid = getqflist({'winid' : 1}).winid
  let l:lid = getloclist(0, {'winid' : 1}).winid
  if l:qid == 0 && l:lid == 0
    silent cwindow
    if &ft != 'qf'
      try
        silent lwindow
      catch /E776/
      endtry
    endif
  elseif l:qid != 0 && l:lid == 0
    silent cclose
    try
      silent lwindow
    catch /E776/
    endtry
  elseif l:qid == 0 && l:lid != 0
    silent lclose
  else
    cclose
    lclose
  endif
endfunction
nnoremap <silent> <script> Q <cmd>call <SID>toggleqf()<CR>

" ============================================================================
" Command
" ============================================================================
" Caputre result for Ex-Command.
command! -nargs=1 -complete=command Capture
\ <mods> new |
\ setlocal buftype=nofile bufhidden=hide noswapfile |
\ call setline(1, split(execute(<q-args>), '\n'))

" ============================================================================
" autocmd
" ============================================================================
" open help in vertical window.
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
function s:cfilter() abort
  let l:query = input('Cfilter: ', '')
  if empty(l:query) | redraw | return | endif
  execute 'Cfilter' l:query
endfunction
augroup vimrc_filetype
  autocmd!
  autocmd FileType gitcommit setlocal spell spelllang=cjk,en
  autocmd FileType git setlocal nofoldenable
  autocmd FileType text setlocal textwidth=0
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
  autocmd FileType qf setlocal signcolumn=no
  autocmd Filetype qf ++once packadd cfilter
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
  autocmd Filetype qf nnoremap <buffer> <LocalLeader>f <cmd>call <SID>cfilter()<CR>
  autocmd Filetype qf nnoremap <buffer> <C-m> <cmd>call <SID>qfenter('wincmd p')<CR>
  autocmd Filetype qf nnoremap <buffer> <C-t> <cmd>call <SID>qfenter('tabnew')<CR>
  autocmd Filetype qf nnoremap <buffer> <C-x> <cmd>call <SID>qfenter('wincmd p <bar> new')<CR>
  autocmd Filetype qf nnoremap <buffer> <C-v> <cmd>call <SID>qfenter('wincmd p <bar> vnew')<CR>
  autocmd BufEnter *.txt,*.jax if &buftype == 'help' | wincmd L | endif
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
" vim-plug
if !filereadable(stdpath('data') .. '/site/autoload/plug.vim')
  echom 'download plug.vim!'
  split
  execute 'terminal curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
  \ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin(stdpath('data') .. '/plugins')
" base
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'neovim/nvim-lspconfig'
" enhanced
Plug 'ChristianChiarulli/nvcode-color-schemes.vim'
Plug 'hoob3rt/lualine.nvim'
Plug 'mhinz/vim-signify'
Plug 'hrsh7th/vim-eft'
Plug 'tyru/columnskip.vim'
Plug 'tyru/caw.vim', { 'on': '<Plug>(caw:hatpos:toggle)' }
Plug 'machakann/vim-sandwich'
Plug 'machakann/vim-swap'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'mattn/vim-findroot'
Plug 'windwp/nvim-autopairs'
" fuzzyfinder
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'gbrlsnchs/telescope-lsp-handlers.nvim'
" Completion
Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/vim-vsnip'
" Extension
Plug 'skywind3000/asyncrun.vim', { 'on': 'AsyncRun', 'for': 'go' }
Plug 'glidenote/memolist.vim', { 'on': [ 'MemoNew', 'MemoList', 'MemoGrep' ] }
Plug 'lambdalisue/gina.vim', { 'on': 'Gina' }
Plug 'thinca/vim-qfreplace', { 'on': 'QfReplace' }
Plug 't9md/vim-quickhl', { 'on': '<Plug>(quickhl-manual-this)' }
Plug 'tweekmonster/startuptime.vim', { 'on': 'StartupTime' }
" FileType
Plug 'kana/vim-altr', { 'for': [ 'go', 'vim', 'help' ] }
Plug 'mattn/vim-gomod', { 'for': 'gomod' }
Plug 'kyoh86/vim-go-coverage', { 'for': 'go' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'godlygeek/tabular', { 'for': 'markdown' }
Plug 'mattn/vim-maketable', { 'for': 'markdown' }
Plug 'iamcco/markdown-preview.nvim', 
\ { 'do': { -> mkdp#util#install() },'for': ['markdown', 'vim-plug']}

call plug#end()

" ============================================================================
" Plugin config
" ============================================================================
" base -----------------------------------------------------------------------
lua require('vimrc')

" enhanced -------------------------------------------------------------------
" nvcode
function s:nvcode_mod() abort
  highlight! link SignifySignAdd             GitSignsAdd
  highlight! link SignifySignChange          GitSignsChange
  highlight! link SignifySignChangeDelete    SignifySignChange
  highlight! link SignifySignDelete          GitSignsDelete
  highlight! link SignifySignDeleteFirstLine SignifySignDelete
  highlight! link DiffAdd GitSignsAdd
  highlight! link DiffChange GitSignsChange
  highlight! link DiffDelete GitSignsDelete
  highlight! link LspReferenceRead Underlined
  highlight! link LspReferenceText Underlined
  highlight! link LspReferenceWrite Underlined
  let g:terminal_color_0 = '#5C6370'
  let g:terminal_color_1 = '#E06C75'
  let g:terminal_color_2 = '#98C379'
  let g:terminal_color_3 = '#E5C07B'
  let g:terminal_color_4 = '#61AFEF'
  let g:terminal_color_5 = '#C678DD'
  let g:terminal_color_6 = '#56B6C2'
  let g:terminal_color_7 = '#ABB2BF'
  let g:terminal_color_8 = '#4B5263'
  let g:terminal_color_9 = '#BE5046'
  let g:terminal_color_10 = '#98C379'
  let g:terminal_color_11 = '#D19A66'
  let g:terminal_color_12 = '#61AFEF'
  let g:terminal_color_13 = '#C678DD'
  let g:terminal_color_14 = '#56B6C2'
  let g:terminal_color_15 = '#3E4452'
endfunction
augroup vimrc_colorscheme
  autocmd!
  autocmd ColorScheme nvcode call s:nvcode_mod()
augroup END
colorscheme nvcode

" lualine.nvim
let g:lualine = {
\ 'options': {
\   'theme': 'codedark',
\   'section_separators' : ['', ''],
\   'component_separators' : ['', ''],
\   'icons_enabled': v:false,
\ },
\ 'sections' : {
\   'lualine_a' : [ ['mode', {'upper': v:true,},], ],
\   'lualine_b' : [ ['branch', {'icon': '', 'icons_enabled': v:true}, ], ],
\   'lualine_c' : [ ['filename', {'file_status': v:true,},],
\                   ['diff'], 
\                   ['diagnostics', { 
\                     'sources': ['nvim_lsp'],
\                     'icons_enabled': v:false,
\                     'symbols': {'error': '×:', 'warn': '⚠:', 'info': 'Ⓘ:'}
\                   }]
\                 ],
\   'lualine_x' : [ 'encoding', 'fileformat', 'filetype' ],
\   'lualine_y' : [ 'progress' ],
\   'lualine_z' : [ 'location' ],
\ },
\ 'inactive_sections' : {
\   'lualine_a' : [  ],
\   'lualine_b' : [  ],
\   'lualine_c' : [ 'filename' ],
\   'lualine_x' : [ 'location' ],
\   'lualine_y' : [  ],
\   'lualine_z' : [  ],
\ },
\ 'extensions' : [ 'fzf' ],
\ }
lua require("lualine").setup()

" vim-signify
let g:signify_disable_by_default = 0
let g:signify_priority = 5
nnoremap <C-y>      <cmd>SignifyToggle<CR>
nnoremap <leader>gu <cmd>SignifyHunkUndo<cr>

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

" caw.vim
let g:caw_no_default_keymappings = 1
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" vim-swap
omap i, <Plug>(swap-textobject-i)
xmap i, <Plug>(swap-textobject-i)
omap a, <Plug>(swap-textobject-a)
xmap a, <Plug>(swap-textobject-a)

" vim-operator-replace
map R <Plug>(operator-replace)

" nvim-autopairs
lua require('nvim-autopairs').setup()

" FuzzyFinder ----------------------------------------------------------------
" telescope.nvim
lua require('vimrc/plugins/telescope')
nnoremap <Leader>f  <cmd>Telescope find_files hidden=true<CR>
nnoremap <Leader>l  <cmd>Telescope current_buffer_fuzzy_find<CR>
nnoremap <Leader>b  <cmd>Telescope buffers<CR>
nnoremap <Leader>gs <cmd>Telescope git_status<CR>

function s:input_grep() abort
  let l:query = input('Grep String: ', '')
  if empty(l:query) | redraw | return | endif
  execute('Telescope grep_string search=' .. l:query)
endfunction
nnoremap <Leader>a  <cmd>call <SID>input_grep()<CR>

" Completion -----------------------------------------------------------------
" nvim-compe
let g:compe = {
\ 'source': {
\   'path': v:true,
\   'buffer': v:true,
\   'nvim_lsp': v:true,
\   'vsnip': v:true,
\ }
\ }

inoremap <silent><expr> <CR>  compe#confirm('<CR>')
inoremap <silent><expr> <C-e> compe#close('<C-e>')
inoremap <silent><expr> <C-y> compe#close('<C-e>')
augroup vimrc_compe
  autocmd!
  autocmd FileType denite-filter call compe#setup({ 'enabled': v:false}, 0)
augroup END

" vim-vsnip
let g:vsnip_snippet_dir =  stdpath('config') .. '/etc/snippets'
imap <expr> <C-l>   vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l>   vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
imap <silent><expr> <TAB>
\ pumvisible() ? compe#confirm(compe#close('<C-e>')) :
\ vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : 
\ <SID>check_back_space() ? "\<TAB>" :
\ compe#complete()

" Extention ------------------------------------------------------------------
" AsyncRun
let s:asyncrun_go_opts = {
\ 'mode': 'term',
\ 'pos': 'bottom',
\ 'rows': &lines/3,
\ 'focus': v:false,
\ }
function! s:asyncrun_gorun(...) abort
  let l:cmd = 'go run ' .. join(a:000)
  call asyncrun#run("", s:asyncrun_go_opts, l:cmd)
endfunction
function! s:asyncrun_gotest(...) abort
  let l:cmd = 'go test ' .. join(a:000)
  call asyncrun#run("", s:asyncrun_go_opts, l:cmd)
endfunction
function s:asyncrun_gotest_func() abort
  let l:test = search('func \(Test\|Example\)', "bcnW")
  if l:test == 0
    echo "[test] no test found immediate to cursor"
    return
  end
  let l:line = getline(test)
  let l:name = split(split(line, " ")[1], "(")[0]
  let l:opts = deepcopy(s:asyncrun_go_opts)
  let l:opts['cwd'] = '$(VIM_FILEDIR)'
  call asyncrun#run("", l:opts, 'go test -v -run ' .. l:name)
endfunction

function s:asyncrun_go_setup() abort
  command! -buffer -nargs=* -complete=file GoRun call s:asyncrun_gorun(<f-args>)
  command! -buffer -nargs=* -complete=file GoTest call s:asyncrun_gotest(<f-args>)
  command! -buffer -nargs=0 GoTestFunc call s:asyncrun_gotest_func()

  nnoremap <buffer> <LocalLeader>r <cmd>GoRun $VIM_RELNAME<CR>
  nnoremap <buffer> <LocalLeader>t <cmd>GoTest ./...<CR>
  nnoremap <buffer> <LocalLeader>p <cmd>GoTest ./$VIM_RELDIR<CR>
  nnoremap <buffer> <LocalLeader>f <cmd>GoTestFunc<CR>
endfunction

augroup vimrc_asyncrun
  au!
  autocmd FileType go call s:asyncrun_go_setup()
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ <cmd>AsyncRun -mode=term -pos=right -cols=80 -focus=0 bash $VIM_RELNAME<CR>
augroup END

" memolist.vim
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = stdpath('config') .. '/etc/memotemplates'
nnoremap <Leader>mn <cmd>MemoNew<CR>
nnoremap <Leader>mg <cmd>MemoGrep<CR>
nnoremap <Leader>ml <cmd>MemoList<CR>

" gina.vim
function s:gina_settings() abort
  let l:gina_cmd_opt = {'noremap': 1, 'silent': 1}
  call gina#custom#command#option('status','-s')
  call gina#custom#command#option('status','--opener', 'tabedit')
  call gina#custom#command#option('log','--opener', 'tabedit')
  call gina#custom#command#option('commit', '-v')
  call gina#custom#command#option('show','--show-signature')
  call gina#custom#command#option('branch','--opener', 'split')

  call gina#custom#mapping#nmap(
  \ '/.*', 'q', '<cmd>bd<CR>', l:gina_cmd_opt
  \ )
  call gina#custom#mapping#nmap(
  \ 'status',
  \ '<C-c>',
  \ '<cmd>Gina commit<CR>',
  \ l:gina_cmd_opt)
  call gina#custom#mapping#nmap(
  \ 'commit', 
  \ '<C-c>', 
  \ '<cmd>Gina status --opener=edit<CR>',
  \ l:gina_cmd_opt)
  call gina#custom#mapping#nmap(
  \ 'status',
  \ 'p',
  \ '<cmd>call gina#action#call(''diff:vsplit'')<CR>',
  \ l:gina_cmd_opt,
  \ )
  call gina#custom#mapping#nmap(
  \ '/\%(blame\|log\|reflog\)',
  \ 'p',
  \ '<cmd>call gina#action#call(''show:commit:vsplit'')<CR>',
  \ l:gina_cmd_opt,
  \ )
  call gina#custom#mapping#nmap(
  \ 'branch',
  \ 'D',
  \ '<cmd>call gina#action#call(''branch:delete'')<CR>',
  \ l:gina_cmd_opt
  \  )

  call gina#custom#execute(
  \ '/\%(ls\|log\|reflog\|grep\)',
  \ 'setlocal noautoread',
  \ )
  call gina#custom#execute(
  \ '/\%(status\|branch\|ls\|log\|reflog\|grep\)',
  \ 'setlocal cursorline',
  \ )
endfunction

augroup vimrc_gina
  autocmd!
  autocmd User gina.vim ++once call s:gina_settings()
augroup END

nnoremap <Leader>gs <cmd>Gina status<CR>
nnoremap <Leader>gl <cmd>Gina log --graph<CR>
nnoremap <Leader>gd <cmd>Gina compare<CR>
nnoremap <Leader>gb <cmd>Gina branch -av<CR>

" vim-quickhl
nmap mm <Plug>(quickhl-manual-this)
xmap mm <Plug>(quickhl-manual-this)
nmap mM <Plug>(quickhl-manual-reset)
xmap mM <Plug>(quickhl-manual-reset)

" FileType -------------------------------------------------------------------
" vim-altr
augroup vimrc_altr
  au!
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>a <Plug>(altr-forward)
  autocmd FileType go,vim,help nmap <buffer> <LocalLeader>b <Plug>(altr-back)
augroup END

" vim-markdown
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_no_default_key_mappings = 1
let g:vim_markdown_emphasis_multiline = 0
augroup vimrc_markdown
  au!
  autocmd FileType markdown nnoremap <buffer> <LocalLeader>o <cmd>Toch<CR>
  autocmd FileType markdown nnoremap <buffer> <LocalLeader>f <cmd>TableFormat<CR>
augroup END

" vim-maketable
augroup vimrc_maketable
  au!
  autocmd FileType markdown vnoremap <silent> <buffer> mt :MakeTable!<CR>
  autocmd FileType markdown nnoremap <buffer>          mt <cmd>UnmakeTable!<CR>
augroup END

" markdown-preview.nvim
augroup vimrc_markdown_preview
  au!
  autocmd FileType markdown nnoremap <buffer> <LocalLeader>p <cmd>MarkdownPreview<CR>
augroup END
