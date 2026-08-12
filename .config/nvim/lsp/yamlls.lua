-- Inactive: yaml lint and format are handled by ryl.
-- To re-enable, add 'yamlls' to the servers list in lsp.lua.
---@type vim.lsp.Config
local config = {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },
  root_markers = {
    '.git/',
  },
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
