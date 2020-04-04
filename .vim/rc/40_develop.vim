" This is plugin setting for my common programing language.

" asyncrun.vim
let g:asyncrun_open = 8
command! -nargs=* Grep AsyncRun -program=grep -strip <f-args>

" vim-test
let g:test#preserve_screen = 1
let test#strategy = "asyncrun_background"

augroup vimrc_dev_plugin
  au!
  " asyncrun.vim
  autocmd FileType go nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 go run $VIM_RELNAME<CR>
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 sh $VIM_RELNAME<CR>
  " vim-test
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> <LocalLeader>t :<C-u>TestFile<CR>
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> TN :<C-u>TestNearest<CR>
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> TF :<C-u>TestFile<CR>
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> TS :<C-u>TestSuite<CR>
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> TL :<C-u>TestLast<CR>
  autocmd FileType go,vim,sh nnoremap <silent> <buffer> TV :<C-u>TestVisit<CR>
  " vim-altr
  autocmd FileType go,vim,sh nmap <buffer> <LocalLeader>a <Plug>(altr-forward)
  autocmd FileType go,vim,sh command! -buffer A  call altr#forward()
augroup END
