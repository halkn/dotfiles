
" coc.nvim
let g:coc_global_extensions = [ 
    \ 'coc-lists',
    \ 'coc-pairs',
    \ 'coc-snippets',
    \ ]

" autocmd
augroup vimrc-coc
  au!
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  autocmd CursorHold * silent call CocActionAsync('highlight')
  autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
augroup END

" mapping
inoremap <silent><expr> <c-space> coc#refresh()
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> <F2> <Plug>(coc-rename)
nmap <leader>ac  <Plug>(coc-codeaction)
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" coc-snippets
let g:coc_snippet_next = '<tab>'
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" CocList
nnoremap <silent> <Leader>L :<C-u>CocList<CR>
nnoremap <silent> <Leader>f :<C-u>CocList files<CR>
nnoremap <silent> <Leader>b :<C-u>CocList buffers<CR>
nnoremap <silent> <Leader>l :<C-u>CocList lines<CR>

