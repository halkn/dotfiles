local icons = require('vimrc.modules.picker.icons')

local source = {
  name = 'files',
  use_preview = true,
}

function source.load(config, opts, callback)
  local items = {}
  local cmd = { 'rg', '--files', '--hidden' }
  for _, glob in ipairs(config.exclude_globs) do
    vim.list_extend(cmd, { '--glob', glob })
  end
  if opts.no_ignore then
    table.insert(cmd, '--no-ignore')
  end
  local job = vim.system(cmd, { text = true }, function(result)
    local raw = {}
    if result.code == 0 and result.stdout then
      for line in result.stdout:gmatch('[^\n]+') do
        table.insert(raw, line)
      end
    end
    vim.schedule(function()
      for _, line in ipairs(raw) do
        local icon = icons.get_icon(line)
        local display = icon and (icon .. ' ' .. line) or line
        table.insert(items, { text = line, display = display })
      end
      callback(items)
    end)
  end)
  return job
end

function source.on_accept(item)
  vim.cmd.edit(item.text)
end

function source.on_accept_split(item, split_cmd)
  vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
end

return source
