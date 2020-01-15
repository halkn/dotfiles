" mapping
nnoremap <silent> <Leader>f :<C-u>Clap files --hidden .<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>
nnoremap <silent> <Leader>l :<C-u>Clap blines<CR>
nnoremap <silent> <Leader>G :<C-u>Clap grep --hidden<CR>
nnoremap <silent> <Leader>q :<C-u>Clap quickfix<CR>
nnoremap <silent> <Leader>L :<C-u>Clap<CR>

" clap-providor for ghq
function! s:open_ghq(selected) abort
  let l:dir = expand(substitute(system('ghq root'), '\n', '', 'g').'/'.a:selected)
  execute ":cd ".l:dir
  execute ":pwd"
endfunction

let g:clap_provider_ghq = {
  \ 'source': 'ghq list' ,
  \ 'sink': function('s:open_ghq'),
  \ }

command! Ghq :Clap ghq
nnoremap <silent> <Leader>R :<C-u>Clap ghq<CR>

" clap-providor for memolist.vim
function! s:find_memo() abort
  let s:sep = &shellslash ? '/' : '\'
  let l:memos = split(expand('$HOME/memo/*.md'), "\n")
  let l:ret = []
  for l:file in l:memos
    call add(l:ret, fnamemodify(l:file, ':t'))
  endfor
  return l:ret
endfunction

function! s:open_memo(selected) abort
  execute ":edit ". expand('$HOME/memo/'. a:selected)
endfunction

let g:clap_provider_memo = {
  \ 'source': function('s:find_memo') ,
  \ 'sink': function('s:open_memo'),
  \ }
nnoremap <Leader>ml :<C-u>Clap memo<CR>
