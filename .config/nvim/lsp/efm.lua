local languages = {
  lua = {
    {
      formatCommand = 'stylua --search-parent-directories --stdin-filepath ${INPUT} -',
      formatStdin = true,
    },
  },
  yaml = {
    {
      formatCommand = 'yamlfmt -in',
      formatStdin = true,
    },
    {
      lintCommand = 'yamllint -f parsable -',
      lintStdin = true,
      lintFormats = {
        '%f:%l:%c: [%trror] %m',
        '%f:%l:%c: [%tarning] %m',
      },
    },
  },
  zsh = {
    {
      formatCommand = 'shfmt -filename ${INPUT}',
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
