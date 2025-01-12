---@type vim.lsp.Config
local config = {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'requirements.txt',
    'uv.lock',
    '.git',
  },
  single_file_support = true,
  settings = {
    pyright = {
      disableOrganizeImports = false,
    },
    python = {
      pythonPath = ".venv/bin/python",
      venvPath = ".",
      venv = ".venv",
      analysis = {
        -- ignore = { '*' },
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'workspace',
        typeCheckingMode = "standard",
      },
    },
  },
}

vim.lsp.config("pyright", config)
vim.lsp.enable("pyright")
