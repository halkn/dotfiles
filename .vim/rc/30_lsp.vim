" vim-lsp-settings ----------------------------------------------------------
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
\ },
\ 'efm-langserver': {
\   'disabled': 0,
\   'whitelist': ['go', 'markdown', 'json', 'sh']
\ }
\}

" vim-lsp -------------------------------------------------------------------
let g:lsp_async_completion = 1
let g:lsp_diagnostics_enabled = 1
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_float_cursor = 0
let g:lsp_signs_priority = 11
let g:lsp_signs_error = {'text': '✗'}
let g:lsp_signs_warning = {'text': '!!'}
let g:lsp_signs_information = {'text': '●'}
let g:lsp_signs_hint = {'text': '▲'}
if has('nvim')
  let g:lsp_diagnostics_echo_cursor = 0
  let g:lsp_virtual_text_prefix = " ‣ "
endif

function! s:setup_lsp() abort
  setlocal omnifunc=lsp#complete
  nmap <silent> <buffer> gd <Plug>(lsp-definition)
  nmap <silent> <buffer> gy <Plug>(lsp-type-definition)
  nmap <silent> <buffer> gr <Plug>(lsp-references)
  nmap <silent> <buffer> K <Plug>(lsp-hover)
  nmap <silent> <buffer> <LocalLeader>k <Plug>(lsp-peek-definition)
  nmap <silent> <buffer> <F2> <Plug>(lsp-rename)
  nmap <silent> <buffer> <LocalLeader>d <plug>(lsp-document-diagnostics)
endfunction

augroup vimrc-lsp-setup
  au!
  " call s:on_lsp_buffer_enabled only for languages that has the server registered.
  autocmd User lsp_buffer_enabled call s:setup_lsp()
  autocmd BufWritePre *.go  call execute('LspDocumentFormatSync') |
    \ call execute('LspCodeActionSync source.organizeImports')
  autocmd BufWrite *.json call execute('LspDocumentFormatSync')
  autocmd BufWrite *.sh call execute('LspDocumentFormatSync')
augroup END

" asyncomplete.vim ----------------------------------------------------------
let g:asyncomplete_auto_completeopt = 0

" vim-vsnip -----------------------------------------------------------------
imap <expr><Tab> vsnip#available(1)    ? '<Plug>(vsnip-expand-or-jump)' : lexima#expand('<LT>Tab>', 'i')
smap <expr><Tab> vsnip#available(1)    ? '<Plug>(vsnip-expand-or-jump)' : lexima#expand('<LT>Tab>', 'i')
imap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : lexima#expand('<LT>S-Tab>', 'i')
smap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : lexima#expand('<LT>S-Tab>', 'i')
let g:vsnip_snippet_dir = expand(g:my_config_dir . '/snippets')

" vim-vsnip-integ -----------------------------------------------------------
let g:vsnip_integ_config = {
\ 'vim_lsp': v:true,
\ 'vim_lsc': v:false,
\ 'lamp': v:false,
\ 'deoplete_lsp': v:false,
\ 'nvim_lsp': v:false,
\ 'language_client_neovim': v:false,
\ 'asyncomplete': v:true,
\ 'deoplete': v:false,
\ 'mucomplete': v:false,
\ }
