local source = {
  name = 'buf_lines',
  use_preview = false,
}

function source.load(_, opts, callback)
  local lines = vim.api.nvim_buf_get_lines(opts.origin_buf, 0, -1, false)
  local items = {}
  for i, line in ipairs(lines) do
    table.insert(items, { text = line, lnum = i })
  end
  vim.schedule(function()
    callback(items)
  end)
  return nil
end

function source.on_accept(item)
  if item.lnum then
    vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
  end
end

function source.on_accept_split(item, split_cmd, origin_buf)
  if origin_buf and vim.api.nvim_buf_is_valid(origin_buf) then
    vim.cmd(split_cmd)
    vim.api.nvim_set_current_buf(origin_buf)
    if item.lnum then
      vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
    end
  end
end

return source
