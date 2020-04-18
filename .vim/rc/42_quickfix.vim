" vim-qf-preview
let g:qfpreview = {
\ 'number': 1,
\ 'sign': {'text': '>>', 'texthl': 'Todo'}
\ }
augroup qfpreview
  autocmd!
  autocmd FileType qf nmap <buffer> p <plug>(qf-preview-open)
augroup END

