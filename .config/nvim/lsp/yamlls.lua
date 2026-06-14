-- NOTE: yaml は efm (yamlfmt + yamllint) に統一済み。
-- 再有効化する場合は lsp.lua の languages.yaml.lsp に 'yamlls' を追加する。
---@type vim.lsp.Config
local config = {
  cmd = { 'yaml-language-server', '--stdio' },
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
