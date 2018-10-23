
" ##############################################################################
" Dein.vim Plugin Manager Load
" ##############################################################################
" CACHE define
let $CACHE = expand('~/.cache')
if !isdirectory(expand($CACHE))
  call mkdir(expand($CACHE), 'p')
endif

" Directory installed plugins by dein
let s:dein_dir = expand('$CACHE/dein/')
" Directory installed dein by itself
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" Check vim runtimepath 
if &runtimepath !~# '/dein.vim'
    " Get dein by git if dein is not installed
    if !isdirectory(s:dein_repo_dir)
        execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
    endif
    " Add the dein installation directory into runtimepath
    set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim
endif

" Load dein
if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)
    call dein#load_toml('~/.config/nvim/rc/dein.toml',          {'lazy': 0})
    call dein#load_toml('~/.config/nvim/rc/dein_lazy.toml',     {'lazy': 1})
"    call dein#load_toml('~/.config/nvim/rc/dein_syntax.toml',   {'lazy': 1})
    call dein#load_toml('~/.config/nvim/rc/dein_neo.toml',      {'lazy': 1})
"    call dein#load_toml('~/.config/nvim/rc/dein_python.toml',   {'lazy': 1})
    call dein#end()
    call dein#save_state()
endif

" auto install
if has('vim_starting') && dein#check_install()
  call dein#install()
endif

" ##############################################################################
" Load Setting
" ##############################################################################
execute 'source' expand('~/.config/nvim/rc/mappings.rc.vim')
execute 'source' expand('~/.config/nvim/rc/options.rc.vim')

" colorscheme 
filetype plugin indent on
syntax enable
set background=dark
colorscheme hybrid
"set termguicolors

