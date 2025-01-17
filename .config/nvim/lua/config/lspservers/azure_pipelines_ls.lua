---@type vim.lsp.Config
local config = {
  cmd = { 'azure-pipelines-language-server', '--stdio' },
  filetypes = { 'yaml' },
  root_markers = {
    "azure-piplies.yml",
    ".git/",
  },
  single_file_support = true,
  settings = {
    yaml = {
      schemas = {
        ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
          "/azure-pipeline*.y*l",
          "/*.azure*",
          "Azure-Pipelines/**/*.y*l",
          "Pipelines/*.y*l",
        },
      },
    },
  },
}

vim.lsp.config("azure-pipelines-language-server", config)
vim.lsp.enable("azure-pipelines-language-server")
