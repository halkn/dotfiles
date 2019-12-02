" Init
set encoding=utf-8
scriptencoding utf-8
let mapleader = "\<Space>"

" Load Scripts
let s:sourceList = [
  \ 'plugin',
  \ 'option',
  \ 'mapping',
  \ 'autocmd',
  \ 'color',
  \ 'go',
  \ 'markdown',
  \ ]
let s:script_path = expand('<sfile>:p:h')
for s:item in s:sourceList
  exec 'source ' . s:script_path . '/rc/' . s:item . '.vim'
endfor

" Release memory
unlet s:script_path
unlet s:sourceList
