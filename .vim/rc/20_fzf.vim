let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'window': { 'width': 0.95, 'height': 0.9 } }

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

function! s:sink_git_log(selected) abort
  let l:tmp = split(a:selected)
  let l:id = l:tmp[match(l:tmp, '[a-f0-9]\{7}')]

  echo l:id
  call popup_create(
  \ term_start(
  \   [&shell, &shellcmdflag, 'git show --color=always ' . l:id],
  \   #{ hidden: 1, term_finish: 'close'}
  \ ),
  \ #{ border: [], minwidth: float2nr(winwidth(0)*0.9), minheight: float2nr(&lines*0.9) }
  \ )
endfunction

function! s:fzf_git_log() abort
  let l:cmd = '
  \ git log
  \ --graph
  \ --color=always
  \ --abbrev=7
  \ --format="%C(auto)%h%d %an %C(blue)%s %C(yellow)%cr"
  \ '

  let l:preview_cmd = '
  \ echo -- {} |
  \ grep -o "[a-f0-9]\{7\}" |
  \ xargs -I @ git show --color=always @ |
  \ diff-so-fancy
  \'

  let l:spec = {
  \ 'source': l:cmd,
  \ 'sink': function('s:sink_git_log'),
  \ 'options': [
  \   '--ansi',
  \   '--exit-0',
  \   '--no-sort',
  \   '--tiebreak=index',
  \   '--preview', l:preview_cmd,
  \   '--bind', 'ctrl-f:preview-page-down,ctrl-b:preview-page-up',
  \   '--bind', 'ctrl-o:toggle-preview',
  \   '--bind', 'ctrl-y:execute:(echo {} | grep -o "[a-f0-9]\{7\}" | pbcopy)',
  \ ]
  \ }
  call fzf#run(fzf#wrap(l:spec))
endfunction

command! FzfGlog call s:fzf_git_log()

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
nnoremap <silent> <Leader>gl :<C-u>FzfGlog<CR>
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})
