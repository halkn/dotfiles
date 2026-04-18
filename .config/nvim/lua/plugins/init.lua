local M = {}
-- hooks --------------------------------------------------------------------
M.hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  -- nvim-treesitter
  if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
    if not ev.data.active then
      vim.cmd.packadd('nvim-treesitter')
    end
    vim.cmd('TSUpdate')
  end
end
vim.api.nvim_create_autocmd('PackChanged', { callback = M.hooks })

-- load plugins -------------------------------------------------------------
local plugs = {}
for _, f in ipairs(vim.fn.glob(vim.fn.stdpath('config') .. '/lua/plugins/*.lua', false, true)) do
  local name = vim.fn.fnamemodify(f, ':t:r')
  if name ~= 'init' then
    local ok, spec = pcall(require, 'plugins.' .. name)
    if ok and spec.src then
      table.insert(plugs, spec)
    elseif not ok then
      vim.notify('[plugins] ' .. name .. ': ' .. spec, vim.log.levels.WARN)
    end
  end
end

-- vim.pack.add
vim.pack.add(vim.tbl_map(function(s)
  return { src = 'https://github.com/' .. s.src, version = s.version }
end, plugs))

-- config load
for _, s in ipairs(plugs) do
  if s.config then
    local ok, err = pcall(s.config)
    if not ok then
      vim.notify('[plugins] ' .. s.src .. ': ' .. err, vim.log.levels.WARN)
    end
  end
end

-- commands -----------------------------------------------------------------
vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update all plugins' })

vim.api.nvim_create_user_command('PackClean', function()
  local inactive = vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()

  if #inactive == 0 then
    vim.notify('Nothing to clean', vim.log.levels.INFO)
    return
  end

  vim.notify('Removing: ' .. table.concat(inactive, ', '), vim.log.levels.INFO)
  vim.pack.del(inactive)
end, { desc = 'Remove plugins not in vim.pack.add()' })

vim.api.nvim_create_user_command('PackReinstall', function(opts)
  local names = vim.split(opts.args, '%s+')
  local specs = vim.tbl_map(function(x)
    return x.spec
  end, vim.pack.get(names))

  vim.pack.del(names, { force = true })
  vim.pack.add(specs)

  vim.notify('Reinstalled: ' .. table.concat(names, ', '), vim.log.levels.INFO)
end, {
  nargs = '+',
  desc = 'Reinstall specified plugins',
  complete = function()
    return vim.tbl_map(function(x)
      return x.spec.name
    end, vim.pack.get())
  end,
})

return M
