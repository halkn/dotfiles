-- input.lua: vim.ui.input をフローティングウィンドウで実装
local M = {}

function M.setup()
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    on_confirm = on_confirm or function() end
    local prompt = (opts.prompt or 'Input'):gsub('%s*:%s*$', '')
    local default = opts.default or ''

    local width = math.max(40, #prompt + 10)
    local row = math.floor((vim.o.lines - 3) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })

    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = row,
      col = col,
      width = width,
      height = 1,
      style = 'minimal',
      border = 'rounded',
      title = ' ' .. prompt .. ' ',
      title_pos = 'center',
    })
    vim.wo[win].wrap = false

    -- カーソルを末尾に
    vim.api.nvim_win_set_cursor(win, { 1, #default })

    local function close_win()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end

    local map_opts = { noremap = true, silent = true, buffer = buf }

    vim.keymap.set('i', '<CR>', function()
      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
      close_win()
      on_confirm(line ~= '' and line or nil)
    end, map_opts)

    vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
      close_win()
      on_confirm(nil)
    end, map_opts)

    vim.keymap.set({ 'i', 'n' }, '<C-c>', function()
      close_win()
      on_confirm(nil)
    end, map_opts)

    -- Emacs風カーソル移動（picker.lua と統一）
    vim.keymap.set('i', '<C-b>', '<Left>', map_opts)
    vim.keymap.set('i', '<C-f>', '<Right>', map_opts)
    vim.keymap.set('i', '<C-a>', '<Home>', map_opts)
    vim.keymap.set('i', '<C-e>', '<End>', map_opts)
    vim.keymap.set('i', '<C-h>', '<BS>', map_opts)

    vim.cmd('startinsert!')
  end
end

return M
