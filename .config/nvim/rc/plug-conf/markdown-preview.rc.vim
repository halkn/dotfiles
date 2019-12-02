augroup vimrc-markdown-preview
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <silent> <Leader>p :<C-u>MarkdownPreview<CR>
augroup END
