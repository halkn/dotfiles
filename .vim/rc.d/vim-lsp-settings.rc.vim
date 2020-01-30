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
  \   'whitelist': ['go', 'markdown']
  \ }
  \}

