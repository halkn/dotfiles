" asyncrun.vim
let g:asyncrun_open = 8
command! -nargs=* Grep AsyncRun -program=grep -strip <f-args>

function s:asyncrun_gotest_func() abort
  let l:test = search('func \(Test\|Example\)', "bcnW")

  if l:test == 0
    echo "[test] no test found immediate to cursor"
    return
  end

  let l:line = getline(test)
  let l:name = split(split(line, " ")[1], "(")[0]
  execute('AsyncRun -mode=term -pos=right -cols=80 -focus=0 -cwd=$(VIM_FILEDIR) go test -v -run ' . l:name)
endfunction

function s:asyncrun_go_setup() abort
  command! -buffer -nargs=* -complete=dir GoRun
  \ AsyncRun -mode=term -pos=right -cols=80 -focus=0  go run $VIM_RELNAME
  command! -buffer -nargs=* -complete=dir GoTest
  \ AsyncRun -mode=term -pos=right -cols=80 -focus=0 go test <f-args>
  command! -buffer -nargs=0 GoTestPackage GoTest ./$VIM_RELDIR
  command! -buffer -nargs=0 GoTestFunc call s:asyncrun_gotest_func()

  nnoremap <silent> <buffer> <LocalLeader>r :<C-u>GoRun<CR>
  nnoremap <silent> <buffer> <LocalLeader>t :<C-u>GoTest ./...<CR>
  nnoremap <silent> <buffer> <LocalLeader>p :<C-u>GoTestPackage<CR>
  nnoremap <silent> <buffer> <LocalLeader>f :<C-u>GoTestFunc<CR>
endfunction

augroup vimrc_asyncrun
  au!
  autocmd FileType go call s:asyncrun_go_setup()
  autocmd FileType sh nnoremap <silent> <buffer> <LocalLeader>r
  \ :<C-u>AsyncRun -mode=term -pos=right -cols=80 -focus=0 bash $VIM_RELNAME<CR>
augroup END
