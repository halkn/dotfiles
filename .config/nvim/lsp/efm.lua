local languages = {
  lua = {
    {
      formatCommand = 'stylua --search-parent-directories --stdin-filepath ${INPUT} -',
      formatStdin = true,
    },
  },
}

---@type vim.lsp.Config
return {
  cmd = { 'efm-langserver' },
  filetypes = vim.tbl_keys(languages),
  root_markers = {
    '.git/',
  },
  single_file_support = true,
  init_options = {
    documentFormatting = true,
    documentDiagnostics = true,
  },
  settings = {
    rootMarkers = {
      '.git/',
    },
    languages = languages,
  },
}
