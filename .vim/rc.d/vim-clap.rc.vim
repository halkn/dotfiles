" mapping
nnoremap <silent> <Leader><Leader> :<C-u>Clap history<CR>
nnoremap <silent> <Leader>f :<C-u>Clap files --hidden .<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>
nnoremap <silent> <Leader>l :<C-u>Clap blines<CR>
nnoremap <silent> <Leader>G :<C-u>Clap grep ++opt=--hidden<CR>
nnoremap <silent> <Leader>q :<C-u>Clap quickfix<CR>
nnoremap <silent> <Leader>gs :<C-u>Clap git_diff_files<CR>
nnoremap <silent> <Leader>e :<C-u>Clap filer<CR>
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
