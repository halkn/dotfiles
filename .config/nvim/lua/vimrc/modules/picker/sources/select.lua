local source = {
  name = 'select',
  use_preview = false,
}

function source.load(_, _, callback)
  vim.schedule(function()
    callback({})
  end)
  return nil
end

function source.on_accept(item)
  vim.cmd.edit(item.text)
end

function source.on_accept_split(item, split_cmd)
  vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(item.text))
end

return source
