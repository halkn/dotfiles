" This is plugin setting for my common programing language.

" vim-quickrun
let g:quickrun_no_default_key_mappings = 1
let g:quickrun_config = {}
let g:quickrun_config = {
\ '_' : {
\   'runner' : 'job',
\   'outputter' : 'error',
\   'outputter/error/success' : 'buffer',
\   'outputter/error/error'   : 'quickfix',
\ }
\}
command! -nargs=+ -complete=command Capture QuickRun -type vim -src <q-args>

" vim-test
let g:test#preserve_screen = 1
let test#strategy = "asyncrun_background"

augroup vimrc_dev_plugin
  au!
  " vim-quickrun
  autocmd FileType go,vim,sh nmap <buffer> <LocalLeader>r <Plug>(quickrun)
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
