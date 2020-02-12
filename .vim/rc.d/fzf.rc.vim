let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } }

command! -bang -nargs=? -complete=dir FzfFiles
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* FzfRg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case --hidden '.shellescape(<q-args>),
  \   1,
  \   fzf#vim#with_preview(), <bang>0
  \ )

function! s:sink_git_status(selected) abort
  let l:key=a:selected[0]
  let l:lines=a:selected[1:]

  if l:key == 'ctrl-m'
    for l:li in l:lines
      let l:fi=split(l:li)[1]
      if l:li[0] == ' ' || l:li[0] == '?'
        call system('git add ' . l:fi)
      else
        call system('git reset -q HEAD '. l:fi)
      endif
    endfor
    call s:fzf_git_status()
  endif

  if len(l:lines) != 1
      echo l:key . ' cannot use multiple selection' 
      return
  endif

  if l:key == 'space'
    execute('!git commit')
    return
  endif

  let l:file=split(a:selected[1])[1]
  if l:key == 'ctrl-e'
    execute('edit ' . l:file)
    return
  endif

  if l:key == 'ctrl-x'
    execute('split ' . l:file)
    return
  endif

  if l:key == 'ctrl-v'
    execute('vsplit ' . l:file)
    return
  endif

endfunction

function! s:fzf_git_status() abort
  let l:spec = {
  \ 'source': 'git status -s',
  \ 'sink*': function('s:sink_git_status'),
  \ 'options': [
  \   '--ansi',
  \   '--multi',
  \   '--expect=ctrl-m,ctrl-e,ctrl-x,ctrl-v,space',
  \   '--preview', 'git diff --color=always -- {-1} | diff-so-fancy',
  \   '--bind', 'ctrl-f:preview-page-down,ctrl-b:preview-page-up',
  \   '--bind', 'ctrl-o:toggle-preview',
  \ ]
  \ }
  call fzf#run(fzf#wrap(l:spec))
endfunction

command! -bang -nargs=* FzfGStatus call s:fzf_git_status()

function! s:open_ghq(selected) abort
  execute 'cd ' . trim(system('ghq root')) . '/' . a:selected
  execute "FzfFiles"
endfunction

command! Ghq call fzf#run({
  \ 'source': 'ghq list',
  \ 'sink': function('s:open_ghq'),
  \ 'options': '--preview "exa -T $(ghq root)/{}"',
  \ 'window': g:fzf_layout['window'],
  \ })

nnoremap <silent> <Leader><Leader> :<C-u>FzfHistory<CR>
nnoremap <silent> <Leader>f :<C-u>FzfFiles<CR>
nnoremap <silent> <Leader>b :<C-u>FzfBuffers<CR>
nnoremap <silent> <Leader>l :<C-u>FzfBLines<CR>
nnoremap <silent> <Leader>R :<C-u>FzfRg<CR>
nnoremap <silent> <Leader>gs :<C-u>FzfGStatus<CR>
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})
