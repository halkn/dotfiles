-- core: load in always.
for _, m in ipairs({
  'vimrc.core',
  'vimrc.lsp',
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
  'vimrc.tools',
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

-- pack: load external plugins.
require('vimrc.pack')
