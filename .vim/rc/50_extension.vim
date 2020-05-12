" memolist.vim
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
let g:memolist_ex_cmd = 'FzfFiles'
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
let g:vista_fzf_preview = ['right:60%']
nnoremap <silent> <c-t> :<c-u>Vista!!<CR>
nnoremap <silent> <Leader>vf :<c-u>Vista finder<CR>

" vim-floaterm
let g:floaterm_width = 0.9
let g:floaterm_height = 0.9

nnoremap <silent> <F7>       :FloatermNew<CR>
tnoremap <silent> <F7>       <C-\><C-n>:FloatermNew<CR>
nnoremap <silent> <F8>       :FloatermPrev<CR>
tnoremap <silent> <F8>       <C-\><C-n>:FloatermPrev<CR>
nnoremap <silent> <F9>       :FloatermNext<CR>
tnoremap <silent> <F9>       <C-\><C-n>:FloatermNext<CR>
nnoremap <silent> <C-@>      :FloatermToggle<CR>
tnoremap <silent> <C-@>      <C-\><C-n>:FloatermToggle<CR>
