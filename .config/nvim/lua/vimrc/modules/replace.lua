-- replace.lua: レジスタの内容でモーション範囲を置き換える operator
local M = {}

function M.op(type)
  local reg = vim.v.register ~= '' and vim.v.register or '"'
  if type == 'line' then
    local s = vim.api.nvim_buf_get_mark(0, '[')[1] - 1
    local e = vim.api.nvim_buf_get_mark(0, ']')[1]
    vim.api.nvim_buf_set_lines(0, s, e, false, vim.fn.getreg(reg, 1, true))
  else
    local s = vim.api.nvim_buf_get_mark(0, '[')
    local e = vim.api.nvim_buf_get_mark(0, ']')
    vim.api.nvim_buf_set_text(
      0,
      s[1] - 1,
      s[2],
      e[1] - 1,
      e[2] + 1,
      vim.split(vim.fn.getreg(reg), '\n', { plain = true })
    )
  end
end

function M.setup()
  _G._vimrc_replace_op = M.op
  vim.keymap.set('n', 'R', function()
    vim.o.operatorfunc = 'v:lua._vimrc_replace_op'
    return 'g@'
  end, { expr = true, noremap = true })
  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode', remap = true })
  vim.keymap.set('x', 'R', function()
    local reg = vim.v.register ~= '' and vim.v.register or '"'
    local saved, saved_type = vim.fn.getreg(reg, 1, true), vim.fn.getregtype(reg)
    vim.cmd('normal! "_d')
    vim.fn.setreg(reg, saved, saved_type)
    vim.cmd('normal! P')
  end, { noremap = true })
end

return M
