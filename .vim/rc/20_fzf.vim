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

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --hidden --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang FzfRG call RipgrepFzf(<q-args>, <bang>0)

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
  let l:key = a:selected[0]

  let l:tmp = split(a:selected[1])
  let l:id = l:tmp[match(l:tmp, '[a-f0-9]\{7}')]

  let l:term_cmd = [
  \ &shell,
  \ &shellcmdflag,
  \ 'git --no-pager show --color=always ' . l:id
  \ ]
  let l:term_opt = {}
  if l:key == 'ctrl-v'
    let l:term_opt.vertical = v:true
  elseif l:key == 'ctrl-m'
    let l:term_opt.curwin = v:true
  endif

  call term_start(l:term_cmd, l:term_opt)
  return
endfunction

function! s:fzf_git_log(...) abort
  let l:cmd = '
  \ git log
  \ --graph
  \ --color=always
  \ --abbrev=7
  \ --format="%C(auto)%h%d %an %C(blue)%s %C(yellow)%cr"
  \ '

  if a:0 >= 1
    let l:cmd = l:cmd . a:1
  endif

  let l:preview_cmd = '
  \ echo -- {} |
  \ grep -o "[a-f0-9]\{7\}" |
  \ xargs -I @ git show --color=always @ $* |
  \ diff-so-fancy
  \'

  let l:spec = {
  \ 'source': l:cmd,
  \ 'sink*': function('s:sink_git_log'),
  \ 'options': [
  \   '--ansi',
  \   '--exit-0',
  \   '--no-sort',
  \   '--tiebreak=index',
  \   '--preview', l:preview_cmd,
  \   '--expect=ctrl-m,ctrl-x,ctrl-v',
  \   '--bind', 'ctrl-f:preview-page-down,ctrl-b:preview-page-up',
  \   '--bind', 'ctrl-o:toggle-preview',
  \   '--bind', 'ctrl-y:execute:(echo -- {} | grep -o "[a-f0-9]\{7\}" | tr -d \\n | pbcopy)',
  \ ]
  \ }
  call fzf#run(fzf#wrap(l:spec))
endfunction

command! FzfCommits call s:fzf_git_log()
command! FzfBCommits call s:fzf_git_log(expand('%'))

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

let s:filer_dir = ''
function! s:open_filer(selected) abort
  " echom a:selected[len(a:selected)-1]
  if a:selected[len(a:selected)-1] == '/'
    " echom '#### dir ####'
    let s:filer_dir = s:filer_dir . a:selected
    call s:fzf_filer(s:filer_dir)
  else
    " echom '#### file ####'
    execute('edit ' . s:filer_dir . a:selected)
    let s:filer_dir = ''
    return
  endif
endfunction

function! s:fzf_filer(...) abort
  call popup_clear()
  let l:cmd = 'ls -aaF1 '
  if a:0 >= 1
    let l:cmd = l:cmd . a:1
  endif
  call fzf#run({
  \ 'source': l:cmd,
  \ 'sink': function('s:open_filer'),
  \ 'window': g:fzf_layout['window'],
  \ })
endfunction
command! FzfFiler call s:fzf_filer()

nnoremap <silent> <Leader><Leader> :<C-u>FzfHistory<CR>
nnoremap <silent> <Leader>f :<C-u>FzfFiles<CR>
nnoremap <silent> <Leader>b :<C-u>FzfBuffers<CR>
nnoremap <silent> <Leader>l :<C-u>FzfBLines<CR>
nnoremap <silent> <Leader>R :<C-u>FzfRG<CR>
nnoremap <silent> <Leader>gs :<C-u>FzfGStatus<CR>
nnoremap <silent> <Leader>gl :<C-u>FzfCommits<CR>
nnoremap <silent> <Leader>F :<C-u>FzfFiler<CR>
inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})

augroup vimrc_fzf
  au!
  autocmd FileType fzf tnoremap <buffer> <silent> <Esc> <Esc>
augroup END
