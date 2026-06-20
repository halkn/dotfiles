local icons = require('vimrc.modules.picker.icons')

local source = {
  name = 'buffers',
  use_preview = false,
}

function source.load(_, _, callback)
  local items = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= '' then
        local icon = icons.get_icon(name)
        local display = icon and (icon .. ' ' .. name) or name
        table.insert(items, { text = name, display = display, buf = buf })
      end
    end
  end
  vim.schedule(function()
    callback(items)
  end)
  return nil
end

function source.on_accept(item)
  if item.buf then
    vim.api.nvim_set_current_buf(item.buf)
  else
    vim.cmd.edit(item.text)
  end
end

function source.on_accept_split(item, split_cmd)
  if item.buf then
    vim.cmd(split_cmd)
    vim.api.nvim_set_current_buf(item.buf)
  else
    vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
  end
end

return source
