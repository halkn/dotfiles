let g:memolist_path = expand('~/memo')
let g:memolist_delimiter_yaml_start = '---'
let g:memolist_delimiter_yaml_end  = '---'
let g:memolist_memo_suffix = 'md'
let g:memolist_template_dir_path = '$HOME/.dotfiles/etc/templates/memotemplates'
nnoremap <Leader>mn :<C-u>MemoNew<CR>
nnoremap <Leader>mg :<C-u>MemoGrep<CR>
nnoremap <Leader>ml :<C-u>Clap memo<CR>

" clap-providor for memolit
function! s:find_memo() abort
  let l:memos = substitute(expand(g:memolist_path.'/*.md'), expand(g:memolist_path."/"), "", "g")
  return split(l:memos, "\n")
endfunction

function! s:open_memo(selected) abort
  execute ":edit ".expand(g:memolist_path.'/'.a:selected)
endfunction

let g:clap_provider_memo = {
  \ 'source': function('s:find_memo') ,
  \ 'sink': function('s:open_memo'),
  \ }

