-- core: load in always.
for _, m in ipairs({
  'core.options',
  'core.mappings',
  'core.autocmds',
  'core.lsp',
}) do
  require(m)
end

-- modules: load local modules.
for _, name in ipairs({
  'vimrc.modules.notify',
  'vimrc.modules.pairs',
  'vimrc.modules.picker',
  'vimrc.modules.statusline',
  'vimrc.modules.terminal',
  'vimrc.modules.yankring',
  'modules.nvim_tools',
}) do
  local ok, mod = pcall(require, name)
  if ok then
    if type(mod) == 'table' and type(mod.setup) == 'function' then
      mod.setup()
    end
  else
    vim.notify('[mod] ' .. name .. ': ' .. mod, vim.log.levels.WARN)
  end
end

-- plugins: load external plugins.
require('plugins')
