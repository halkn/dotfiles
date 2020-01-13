let g:markdown_fenced_languages = [
  \ 'go',
  \ 'sh'
  \]
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_conceal_code_blocks = 1
augroup vimrc-vim-markdown
  au!
  autocmd FileType markdown nnoremap <buffer> <silent> <C-t> :<C-u>Toc<CR>
augroup END
