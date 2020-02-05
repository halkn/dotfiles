let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } }

command! -bang -nargs=? -complete=dir FzfFiles
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* FzfRg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case --hidden '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

nnoremap <silent> <Leader><Leader> :<C-u>FzfHistory<CR>
nnoremap <silent> <Leader>f :<C-u>FzfFiles<CR>
nnoremap <silent> <Leader>b :<C-u>FzfBuffers<CR>
nnoremap <silent> <Leader>l :<C-u>FzfBLines<CR>
nnoremap <silent> <Leader>R :<C-u>FzfRg<CR>
nnoremap <silent> <Leader>gs :<C-u>FzfGFiles?<CR>
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})
