" ##############################################################################
" function define
" ##############################################################################
function! s:source_rc(path, ...) abort 
  let l:use_global = get(a:000, 0, !has('vim_starting'))
  let l:abspath = resolve(expand('~/.vim/rc/' . a:path))
  if !l:use_global
    execute 'source' fnameescape(l:abspath)
    return
  endif

  " substitute all 'set' to 'setglobal'
  let l:content = map(readfile(l:abspath),
        \ 'substitute(v:val, "^\\W*\\zsset\\ze\\W", "setglobal", "")')
  " create tempfile and source the tempfile
  let l:tempfile = tempname()
  try
    call writefile(l:content, l:tempfile)
    execute 'source' fnameescape(l:tempfile)
  finally
    if filereadable(l:tempfile)
      call delete(l:tempfile)
    endif
  endtry
endfunction"}}}

" ##############################################################################
" Dein.vim Plugin Manager Load
" ##############################################################################
" CACHE define
let $CACHE = expand('~/.cache')
if !isdirectory(expand($CACHE))
  call mkdir(expand($CACHE), 'p')
endif

if &compatible
 set nocompatible
endif

" Add the dein installation directory into runtimepath
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Load dein
let s:dein_dir = expand('$CACHE/dein')
if dein#load_state(s:dein_dir)
 call dein#begin(s:dein_dir)
 call dein#load_toml('~/.vim/rc/dein.toml',          {'lazy': 0})
 call dein#load_toml('~/.vim/rc/dein_lazy.toml',     {'lazy': 1})
 call dein#load_toml('~/.vim/rc/dein_syntax.toml',   {'lazy': 1})
 call dein#load_toml('~/.vim/rc/dein_neo.toml',      {'lazy': 1})
 call dein#load_toml('~/.vim/rc/dein_python.toml',   {'lazy': 1})
 call dein#end()
 call dein#save_state()
endif

" auto install
if dein#check_install()
  call dein#install()
endif

" ##############################################################################
" Load Setting
" ##############################################################################
call s:source_rc('mappings.rc.vim')
call s:source_rc('options.rc.vim')

" for WSL 
if system('uname -a | grep Microsoft') != ""
    call s:source_rc('wsl.rc.vim')       
endif

" colorscheme 
set t_Co=256
set background=dark
colorscheme iceberg
filetype plugin indent on
syntax on

