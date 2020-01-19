let g:previm_disable_default_css = 1
let g:previm_custom_css_path = '$HOME/.dotfiles/etc/templates/previm/markdown.css'
augroup vimrc-Previm
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p :<C-u>PrevimOpen<CR>
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>r :<C-u>call previm#refresh()<CR>
augroup END
