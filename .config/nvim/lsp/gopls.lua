---@type vimrc.lsp.Config
local config = {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
  format_code_actions = { 'source.organizeImports' },
  settings = {
    gopls = {
      gofumpt = true,
      usePlaceholders = true,
      semanticTokens = true,
      templateExtensions = { 'gotmpl', 'gohtml' },
      -- true enables every staticcheck analyzer; drop the key to fall back to
      -- the subset gopls selects for precision.
      staticcheck = true,
      analyses = {
        shadow = true,
        appendclipped = true,
        slicesdelete = true,
      },
      codelenses = {
        test = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        ignoredError = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}

return config
