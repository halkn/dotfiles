let s:start_plugs_global = [
  \ ['arcticicestudio/nord-vim', {}],
  \ ['itchyny/lightline.vim', {}],
  \ ['vim-jp/vimdoc-ja', {}],
  \ ['cpohama/lexima.vim', {}],
  \ ['tpope/vim-commentary', {}],
  \ ['kana/vim-operator-user', {}],
  \ ['kana/vim-operator-replace', {}],
  \ ['machakann/vim-sandwich', {}],
  \ ['rhysd/git-messenger.vim', {}],
  \ ['mhinz/vim-signify', {}],
  \ ['simeji/winresizer', {}],
  \ ['glidenote/memolist.vim', {}],
  \ ['mbbill/undotree', {}],
  \ ['mattn/vim-findroot', {}],
  \ ['junegunn/fzf', {}],
  \ ['junegunn/fzf.vim', {}],
  \ ]
let s:start_plugs_lsp = [
  \ ['prabirshrestha/async.vim', {'type': 'opt'}],
  \ ['prabirshrestha/vim-lsp', {'type': 'opt'}],
  \ ['mattn/vim-lsp-settings', {'type': 'opt'}],
  \ ['prabirshrestha/asyncomplete.vim', {'type': 'opt'}],
  \ ['prabirshrestha/asyncomplete-lsp.vim', {'type': 'opt'}],
  \ ['hrsh7th/vim-vsnip', {'type': 'opt'}],
  \ ['hrsh7th/vim-vsnip-integ', {'type': 'opt'}]
  \ ]
let s:opt_plugs_dev = [
  \ ['kana/vim-altr', {'type': 'opt'}],
  \ ['liuchengxu/vista.vim', {'type': 'opt'}],
  \ ['thinca/vim-quickrun', {'type': 'opt'}],
  \ ['janko/vim-test', {'type': 'opt'}],
  \ ]
let s:opt_plugs_markdown = [
  \ ['previm/previm', {'type': 'opt'}],
  \ ['dhruvasagar/vim-table-mode', {'type': 'opt'}],
  \ ['tyru/open-browser.vim', {'type': 'opt'}],
  \ ]

" Define user commands for updating/cleaning the plugins.
function! PackInit() abort
  packadd minpac

  call minpac#init()
  call minpac#add('k-takata/minpac', {'type': 'opt'})

  call map(
  \ s:start_plugs_global+s:start_plugs_lsp+s:opt_plugs_dev+s:opt_plugs_markdown,
  \ {_, val -> execute('call minpac#add("' . val[0] . '", ' . string(val[1]) . ')') }
  \ )
endfunction
command! PackUpdate call PackInit() | call minpac#update('', {'do': 'call minpac#status()'})
command! PackClean  call PackInit() | call minpac#clean()
command! PackStatus call PackInit() | call minpac#status()

" Define function to setup a plugin
function! s:setup_plugins(plugs) abort
  for l:plug in a:plugs
    let l:name = split(l:plug[0], '/')[1]
    let l:type = get(l:plug[1], 'type', 'start')
    let l:setup_file = glob(
      \ g:my_config_dir . '/rc.d/'
      \ .substitute(l:name, '\.vim', '', 'g')
      \ .'.rc.vim'
      \ )
    if l:setup_file != ''
      exe 'source '.l:setup_file
    endif
    if l:type ==# 'opt'
      exe 'packadd '.l:name
    endif
  endfor
endfunction

" Difine function to lazy load a plugin
function! s:lazy_load_plugins(plugs, ft, augrp) abort
  execute('au! ' . a:augrp)
  call s:setup_plugins(a:plugs)
  execute('doautocmd FileType ' . a:ft)
endfunction

" Setup plugins
" For global plugins
call s:setup_plugins(s:start_plugs_global)

" For FileType plugins
augroup vimrc-lazy-lsp
  au!
  autocmd Filetype go,sh,python,java,json,yaml,vim,markdown,dockerfile
    \ call s:lazy_load_plugins(s:start_plugs_lsp, &filetype, 'vimrc-lazy-lsp') |
    \ call lsp#enable()
augroup END
augroup vimrc-lazy-dev
  au!
  autocmd Filetype sh,go,python 
    \ call s:lazy_load_plugins(s:opt_plugs_dev, &filetype, 'vimrc-lazy-dev')
augroup END
augroup vimrc-lazy-markdown
  au!
  autocmd Filetype markdown 
    \ call s:lazy_load_plugins(s:opt_plugs_markdown, &filetype, 'vimrc-lazy-markdown')
augroup END

" Global command that use opt plugin.
command! -nargs=+ -complete=command Capture packadd vim-quickrun | QuickRun -type vim -src <q-args>
