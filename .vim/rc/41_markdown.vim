let g:table_mode_corner = '|'
let g:table_mode_map_prefix = '<LocalLeader>'

augroup vimrc_markdown_preview
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p :<C-u>MarkdownPreview<CR>
augroup END
