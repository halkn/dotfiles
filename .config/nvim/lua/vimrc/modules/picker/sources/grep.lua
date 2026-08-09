local source = {
  name = 'grep',
  use_preview = true,
  debounce_query = true,
}

function source.load(_, _, callback)
  vim.schedule(function()
    callback({})
  end)
  return nil
end

function source.filter(_items, _query)
  return _items
end

function source.on_query_change(query, ctx)
  ctx.cancel_job()

  if query == '' then
    ctx.set_items({}, {})
    ctx.render()
    ctx.update_cursor()
    ctx.update_preview()
    return
  end

  local job
  job = vim.system({ 'rg', '--vimgrep', '--', query }, { text = true }, function(result)
    local items = {}
    if result.stdout then
      for line in result.stdout:gmatch('[^\n]+') do
        table.insert(items, { text = line })
      end
    end
    vim.schedule(function()
      if not ctx.is_current_job(job) then
        return
      end
      ctx.set_items(items, items)
      ctx.render()
      ctx.update_cursor()
      ctx.update_preview()
    end)
  end)
  ctx.set_job(job)
end

function source.on_accept(item)
  local path, lnum = item.text:match('^([^:]+):(%d+):')
  if path then
    vim.cmd.edit(path)
    if lnum then
      vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
    end
  end
end

function source.on_accept_split(item, split_cmd)
  local path, lnum = item.text:match('^([^:]+):(%d+):')
  if path then
    vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(path))
    if lnum then
      vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
    end
  end
end

function source.preview_file(item)
  local path, lnum = item.text:match('^([^:]+):(%d+):')
  if path then
    return path, tonumber(lnum)
  end
  return nil, nil
end

return source
