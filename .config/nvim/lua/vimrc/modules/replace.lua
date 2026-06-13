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

return M
