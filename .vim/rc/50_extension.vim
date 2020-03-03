" caw.vim
nmap <Leader>c <Plug>(caw:zeropos:toggle)
vmap <Leader>c <Plug>(caw:zeropos:toggle)

" vim-operator-replace
map R <Plug>(operator-replace)

" memolist.vim
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
let g:memolist_fzf = 1
nnoremap <Leader>mn :<C-u>MemoNew<CR>
nnoremap <Leader>mg :<C-u>MemoGrep<CR>
nnoremap <Leader>ml :<C-u>MemoList<CR>

" undotree
nnoremap <silent> <Leader>u :UndotreeToggle<cr>
let g:undotree_WindowLayout = 2

" winresizer
let g:winresizer_start_key = '<C-w>r'
nnoremap <silent> <C-w>r :WinResizerStartResize<CR>

" vim-signify
noremap <silent> <C-y> :SignifyToggle<CR>
noremap <silent> <Leader>gd :SignifyDiff<CR>
let g:signify_disable_by_default = 0

" vista.vim
let g:vista_default_executive = 'vim_lsp'
let g:vista_close_on_jump = 1
let g:vista#renderer#enable_icon = 0
nnoremap <silent> <c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder<CR>
