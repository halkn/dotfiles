local picker = require('vimrc.modules.picker')

picker.setup()

local function run()
  for _, source in ipairs({ 'files', 'buffers', 'grep', 'buf_lines', 'tree', 'git' }) do
    picker.open(source)
    vim.wait(100)
    picker.close()
  end

  local selected
  picker.ui_select({ 'a', 'b' }, { prompt = 'module test' }, function(value)
    selected = value
  end)
  vim.wait(100)
  assert(vim.api.nvim_get_current_buf() ~= 0)
  picker.close()
  assert(selected == nil)
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
end
io.write('picker modules test passed\n')
vim.cmd('qa!')
