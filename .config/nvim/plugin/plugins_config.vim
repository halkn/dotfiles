" nvim-compe
" vim-vsnip
" vim-vsnip-integ
packadd nvim-compe
packadd vim-vsnip
packadd vim-vsnip-integ
smap <expr> <C-l>   vsnip#expandable() ? '<Plug>(vsnip-expand)'    : '<C-l>'
imap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
let g:vsnip_snippet_dir = expand(fnamemodify($MYVIMRC, ":h") . '/snippets')

let g:compe_enabled = v:true
let g:compe_min_length = 1
let g:compe_auto_preselect = v:true " or v:false
let g:compe_source_timeout = 200
let g:compe_incomplete_delay = 400
lua require'compe_nvim_lsp'.attach()
call compe#source#vim_bridge#register('path', compe_path#source#create())
call compe#source#vim_bridge#register('vsnip', compe_vsnip#source#create())
inoremap <expr><C-l> compe#confirm(lexima#expand('<LT>CR>', 'i'))
inoremap <expr><CR>  compe#confirm(lexima#expand('<LT>CR>', 'i'))
inoremap <expr><C-e> compe#close('<C-e>')

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
