require('vimrc.lsp.lang.schema')

---@type string[]
local language_order = {
  'python',
  'lua',
  'zsh',
  'bash',
  'markdown',
  'yaml',
}

---@type table<string, vimrc.lsp.lang.LanguageConfig>
local languages = {
  python = {
    enabled = true,
    filetypes = { 'python' },
    lsp = { 'ty', 'ruff' },
    format = {
      client = 'ruff',
    },
  },
  lua = {
    enabled = true,
    filetypes = { 'lua' },
    lsp = { 'luals', 'efm' },
    format = {
      client = 'efm',
      tool = 'stylua',
    },
  },
  zsh = {
    enabled = true,
    filetypes = { 'zsh' },
    lsp = { 'efm' },
    format = {
      client = 'efm',
      tool = 'shfmt',
    },
  },
  bash = {
    enabled = false,
    filetypes = { 'bash', 'sh' },
    lsp = { 'bashls' },
    format = {
      client = 'bashls',
    },
  },
  markdown = {
    enabled = true,
    filetypes = { 'markdown' },
    lsp = { 'rumdl' },
    format = {
      client = 'rumdl',
    },
  },
  yaml = {
    enabled = true,
    filetypes = { 'yaml' },
    lsp = { 'yamlls' },
    format = {
      client = 'yamlls',
    },
  },
}

return {
  language_order = language_order,
  languages = languages,
}
