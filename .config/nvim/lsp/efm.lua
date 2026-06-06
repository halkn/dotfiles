local lang = require('vimrc.lsp.lang')

local formatters = {
  shfmt = {
    formatCommand = 'shfmt -filename ${INPUT}',
    formatStdin = true,
  },
  stylua = {
    formatCommand = 'stylua --search-parent-directories --stdin-filepath ${INPUT} -',
    formatStdin = true,
  },
  yamlfmt = {
    formatCommand = 'yamlfmt -in',
    formatStdin = true,
  },
}

local linters = {
  yamllint = {
    lintCommand = 'yamllint -f parsable -',
    lintStdin = true,
    lintFormats = {
      '%f:%l:%c: [%trror] %m',
      '%f:%l:%c: [%tarning] %m',
    },
  },
}

local format_tools_by_ft = lang.format_tools_by_ft('efm')
local lint_tools_by_ft = lang.lint_tools_by_ft('efm')

local function efm_filetypes()
  local seen, filetypes = {}, {}
  for ft in pairs(format_tools_by_ft) do
    if not seen[ft] then
      table.insert(filetypes, ft)
      seen[ft] = true
    end
  end
  for ft in pairs(lint_tools_by_ft) do
    if not seen[ft] then
      table.insert(filetypes, ft)
      seen[ft] = true
    end
  end
  table.sort(filetypes)
  return filetypes
end

local function efm_languages()
  local languages = {}

  for filetype, tool in pairs(format_tools_by_ft) do
    local formatter = formatters[tool]
    if formatter == nil then
      error(('missing efm formatter config: %s'):format(tool))
    end
    languages[filetype] = languages[filetype] or {}
    table.insert(languages[filetype], vim.deepcopy(formatter))
  end

  for filetype, tool in pairs(lint_tools_by_ft) do
    local linter = linters[tool]
    if linter == nil then
      error(('missing efm linter config: %s'):format(tool))
    end
    languages[filetype] = languages[filetype] or {}
    table.insert(languages[filetype], vim.deepcopy(linter))
  end

  return languages
end

---@type vim.lsp.Config
local config = {
  cmd = { 'efm-langserver' },
  filetypes = efm_filetypes(),
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
    languages = efm_languages(),
  },
}

return config
