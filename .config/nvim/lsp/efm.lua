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
}

local format_tools_by_ft = lang.format_tools_by_ft('efm')

local function efm_filetypes()
  local filetypes = vim.tbl_keys(format_tools_by_ft)
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

    languages[filetype] = { vim.deepcopy(formatter) }
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
  },
  settings = {
    rootMarkers = {
      '.git/',
    },
    languages = efm_languages(),
  },
}

return config
