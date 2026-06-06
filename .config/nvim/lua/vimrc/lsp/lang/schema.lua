---@class vimrc.lsp.lang.FormatConfig
---@field client string
---@field tool? string

---@class vimrc.lsp.lang.LintConfig
---@field client string
---@field tool string

---@class vimrc.lsp.lang.LanguageConfig
---@field enabled boolean
---@field filetypes string[]
---@field lsp? string[]
---@field format? vimrc.lsp.lang.FormatConfig
---@field lint? vimrc.lsp.lang.LintConfig

return {}
