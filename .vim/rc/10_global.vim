" sonokai
let g:sonokai_disable_italic_comment = 1
let g:sonokai_enable_italic = 0
let g:sonokai_menu_selection_background = 'blue'
silent! colorscheme sonokai

highlight link LspErrorText CocErrorSign
highlight link LspErrorHighlight CocErrorHighlight
highlight link LspWarningText CocWarningSign
highlight link LspWarningHighlight CocWarningHighlight

" lightline
let g:lightline = {
\ 'colorscheme': 'sonokai',
\ 'active': {
\   'left': [ [ 'mode', 'paste' ],
\             [ 'readonly', 'filename', 'modified' ],
\             [ 'lsp_errors', 'lsp_warnings', 'lsp_ok' ] ]
\ },
\ 'component_expand': {
\   'lsp_warnings': 'LightlineLSPWarnings',
\   'lsp_errors':   'LightlineLSPErrors',
\   'lsp_ok':       'LightlineLSPOk',
\ },
\ 'component_type': {
\   'lsp_warnings': 'warning',
\   'lsp_errors':   'error',
\   'lsp_ok':       'middle',
\ },
\ }

function! LightlineLSPWarnings() abort
  let l:counts = lsp#ui#vim#diagnostics#get_buffer_diagnostics_counts()
  return l:counts.warning == 0 ? '' : printf('!!:%d', l:counts.warning)
endfunction

function! LightlineLSPErrors() abort
  let l:counts = lsp#ui#vim#diagnostics#get_buffer_diagnostics_counts()
  return l:counts.error == 0 ? '' : printf('✗:%d', l:counts.error)
endfunction

function! LightlineLSPOk() abort
  let l:counts =  lsp#ui#vim#diagnostics#get_buffer_diagnostics_counts()
  let l:total = l:counts.error + l:counts.warning
  return l:total == 0 ? 'OK' : ''
endfunction

augroup LightLineOnLSP
  autocmd!
  autocmd User lsp_diagnostics_updated call lightline#update()
augroup END