" Enable auto complete
let g:lsp_async_completion = 1

" Enable Document diagnostics
let g:lsp_diagnostics_enabled = 1
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '!!'}
let g:lsp_signs_information = {'text': '●'}
let g:lsp_signs_hint = {'text': '▲'}

let g:lsp_settings = {
  \ 'gopls': {
  \   'workspace_config': { 'gopls':
  \     {
  \       'hoverKind': 'SynopsisDocumentation',
  \       'completeUnimported': v:true,
  \       'usePlaceholders': v:true,
  \       'staticcheck': v:true,
  \     }
  \   }
  \ }
  \}

function! s:setup_lsp() abort
  setlocal omnifunc=lsp#complete
  nmap <silent> <buffer> gd <Plug>(lsp-definition)
  nmap <silent> <buffer> gy <Plug>(lsp-type-definition)
  nmap <silent> <buffer> gr <Plug>(lsp-references)
  nmap <silent> <buffer> K <Plug>(lsp-hover)
  nmap <silent> <buffer> <Leader>k <Plug>(lsp-peek-definition)
  nmap <silent> <buffer> <F2> <Plug>(lsp-rename)
endfunction

" efm-langserver ( markdown )
function! s:setup_efm_langserver() abort
  if executable('efm-langserver')
    call lsp#register_server({
      \ 'name': 'efm-langserver',
      \ 'cmd': {server_info->['efm-langserver']},
      \ 'whitelist': ['markdown'],
      \ })
  endif
endfunction

augroup vimrc-lsp-setup
  au!
  " call s:on_lsp_buffer_enabled only for languages that has the server registered.
  autocmd User lsp_buffer_enabled call s:setup_lsp()
  autocmd FileType markdown call s:setup_efm_langserver()
  autocmd BufWritePre *.go  call execute('LspDocumentFormatSync') |
    \ call execute('LspCodeActionSync source.organizeImports')
augroup END
