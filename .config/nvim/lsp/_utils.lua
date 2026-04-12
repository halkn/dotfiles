local M = {}

---Detect whether the root directory uses uv-managed Python environment.
---@param root_dir string|nil
---@return boolean
function M.has_uv_project(root_dir)
  if not root_dir or root_dir == '' then
    return false
  end

  return vim.uv.fs_stat(vim.fs.joinpath(root_dir, 'uv.lock')) ~= nil
    or vim.uv.fs_stat(vim.fs.joinpath(root_dir, '.venv')) ~= nil
end

return M
