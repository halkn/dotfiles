
augroup vimrc-Filetype
  autocmd!
  autocmd FileType gitcommit setlocal spell spelllang=cjk,en
  autocmd FileType git setlocal nofoldenable
  autocmd FileType text setlocal textwidth=0
  autocmd FileType vim setlocal foldmethod=marker tabstop=2 shiftwidth=2
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2
  autocmd FileType zsh setlocal tabstop=2 shiftwidth=2
  autocmd FileType markdown setlocal tabstop=2 shiftwidth=2
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
augroup END

augroup vimrc-help
  autocmd!
  autocmd FileType help wincmd L
  autocmd FileType help nnoremap <silent> <buffer> q <C-w>c
augroup END

augroup vimrc-quickfix
  autocmd!
  autocmd Filetype qf nnoremap <silent> <buffer> p <CR>zz<C-w>p
  autocmd Filetype qf nnoremap <silent> <buffer> q <C-w>c
augroup END
