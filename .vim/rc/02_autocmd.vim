" indent by FileType
augroup vimrc-ft-indent
  autocmd!
  autocmd FileType gitcommit setlocal spell spelllang=cjk,en
  autocmd FileType git setlocal nofoldenable
  autocmd FileType text setlocal textwidth=0
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2
  autocmd FileType zsh setlocal tabstop=2 shiftwidth=2
augroup END

" quickfix
augroup vimrc-ft-quickfix
  autocmd!
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
augroup END

" vim help
augroup vimrc-ft-help
  autocmd!
  autocmd FileType help wincmd L
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
augroup END
