local M = {}

local original_ui_select = vim.ui.select

function M.open(open, items, opts, on_choice)
  if type(opts) == 'function' and on_choice == nil then
    on_choice = opts
    opts = nil
  end
  opts = opts or {}
  on_choice = on_choice or function() end

  if type(items) ~= 'table' then
    return original_ui_select(items, opts, on_choice)
  end

  local picker_items = vim.tbl_map(function(item)
    return { text = (opts.format_item or tostring)(item), value = item }
  end, items)
  return open('select', {
    title = opts.prompt or 'select',
    items = picker_items,
    on_select = function(picked)
      on_choice(picked and picked.value or nil)
    end,
  })
end

function M.install(open)
  vim.ui.select = function(items, opts, on_choice)
    return M.open(open, items, opts, on_choice)
  end
end

return M
