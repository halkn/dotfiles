-- Operator that replaces the motion range with the contents of a register.
local M = {}

---@class vimrc.replace.Mappings
---@field replace string?

---@class vimrc.replace.Setup
---@field mappings vimrc.replace.Mappings?

function M.op(type)
  local reg = vim.v.register ~= '' and vim.v.register or '"'
  if type == 'line' then
    local s = vim.api.nvim_buf_get_mark(0, '[')[1] - 1
    local e = vim.api.nvim_buf_get_mark(0, ']')[1]
    vim.api.nvim_buf_set_lines(0, s, e, false, vim.fn.getreg(reg, 1, true))
  else
    local s = vim.api.nvim_buf_get_mark(0, '[')
    local e = vim.api.nvim_buf_get_mark(0, ']')
    -- getreg() without the list argument always returns a string.
    local contents = vim.fn.getreg(reg) --[[@as string]]
    vim.api.nvim_buf_set_text(
      0,
      s[1] - 1,
      s[2],
      e[1] - 1,
      e[2] + 1,
      vim.split(contents, '\n', { plain = true })
    )
  end
end

---@param opts vimrc.replace.Setup?
function M.setup(opts)
  _G._vimrc_replace_op = M.op
  local mappings = opts and opts.mappings or {}
  if mappings.replace and mappings.replace ~= '' then
    vim.keymap.set('n', mappings.replace, function()
      vim.o.operatorfunc = 'v:lua._vimrc_replace_op'
      return 'g@'
    end, { expr = true, noremap = true })
    vim.keymap.set('x', mappings.replace, function()
      local reg = vim.v.register ~= '' and vim.v.register or '"'
      local saved, saved_type = vim.fn.getreg(reg, 1, true), vim.fn.getregtype(reg)
      vim.cmd('normal! "_d')
      vim.fn.setreg(reg, saved, saved_type)
      vim.cmd('normal! P')
    end, { noremap = true })
  end
end

return M
