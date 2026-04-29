---@type vim.lsp.Config
local config = {
  cmd = { require('tools').executable('yaml-language-server'), '--stdio' },
  filetypes = { 'yaml' },
  root_markers = {
    '.git/',
  },
  single_file_support = true,
  settings = {
    yaml = {
      format = {
        enable = true,
      },
      schemaStore = {
        enable = true,
      },
      schemas = {
        ['https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json'] = {
          '/azure-pipeline*.y*l',
          '/*.azure*',
          'Azure-Pipelines/**/*.y*l',
          'Pipelines/*.y*l',
        },
      },
      validate = true,
    },
  },
}

return config
