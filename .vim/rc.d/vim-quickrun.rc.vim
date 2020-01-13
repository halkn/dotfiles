let g:quickrun_config = {}
let g:quickrun_config = {
  \ '_' : {
    \ 'runner' : 'job',
    \ 'outputter' : 'error',
    \ 'outputter/error/success' : 'buffer',
    \ 'outputter/error/error'   : 'quickfix',
  \ }
\}
