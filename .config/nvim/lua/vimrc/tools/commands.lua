local M = {}
local configured = false

local function notify_result(action, results)
  if #results == 0 then
    vim.notify('No managed tools selected', vim.log.levels.INFO)
    return
  end

  for _, result in ipairs(results) do
    local status = result.skipped and 'already installed' or action
    vim.notify(('%s: %s -> %s'):format(result.name, status, result.path), vim.log.levels.INFO)
  end
end

function M.setup()
  if configured then
    return
  end
  configured = true

  vim.api.nvim_create_user_command('NvimToolsList', function()
    local tools = require('vimrc.tools')
    local required = tools.required_by_languages()
    local lines = vim.tbl_map(function(item)
      local required_by = required[item.name] and table.concat(required[item.name], ',') or '-'
      if tools.registry[item.name].common then
        required_by = required_by == '-' and 'common' or (required_by .. ',common')
      end
      local status = item.installed and 'installed' or 'missing'
      return ('%-20s %-9s required_by=%s path=%s'):format(item.name, status, required_by, item.path)
    end, tools.list())

    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, { desc = 'List Neovim managed tools' })

  vim.api.nvim_create_user_command('NvimToolsInstall', function(opts)
    local ok, results = pcall(require('vimrc.tools.installer').install, opts.args)
    if not ok then
      vim.notify(results, vim.log.levels.ERROR)
      return
    end
    notify_result('installed', results)
  end, {
    nargs = '?',
    complete = function()
      return vim.tbl_keys(require('vimrc.tools').registry)
    end,
    desc = 'Install Neovim managed tools',
  })

  vim.api.nvim_create_user_command('NvimToolsUpdate', function(opts)
    local ok, results = pcall(require('vimrc.tools.installer').update, opts.args)
    if not ok then
      vim.notify(results, vim.log.levels.ERROR)
      return
    end
    notify_result('updated', results)
  end, {
    nargs = '?',
    complete = function()
      return vim.tbl_keys(require('vimrc.tools').registry)
    end,
    desc = 'Update Neovim managed tools',
  })
end

return M
