-- core: load in always.
for _, m in ipairs({
  'core.options',
  'core.mappings',
  'core.autocmds',
  'core.lsp',
}) do
  require(m)
end

-- modules: load my modules.
for _, f in ipairs(vim.fn.glob(vim.fn.stdpath('config') .. '/lua/modules/*.lua', false, true)) do
  local name = 'modules.' .. vim.fn.fnamemodify(f, ':t:r')
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
