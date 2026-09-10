local M = {}
local max_bytes, max_lines, max_line_length = 1024 * 1024, 2000, 2000

---@class vimrc.explorer.Preview
---@field enabled boolean
---@field generation integer
---@field win integer?
---@field buf integer?
---@field path string?
local Preview = {}
Preview.__index = Preview

function M.new()
  return setmetatable({ enabled = false, generation = 0 }, Preview)
end

function Preview:hide()
  self.generation = self.generation + 1
  local win, buf = self.win, self.buf
  self.win, self.buf, self.path = nil, nil, nil
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function content(path)
  local lines, ft, truncated
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == path then
      local total = vim.api.nvim_buf_line_count(buf)
      local count = math.min(total, max_lines)
      truncated = total > max_lines
      if vim.api.nvim_buf_get_offset(buf, count) > max_bytes then
        return { '[Buffer exceeds 1 MiB preview limit]' }
      end
      lines = vim.api.nvim_buf_get_lines(buf, 0, max_lines, false)
      ft = vim.bo[buf].filetype
      break
    end
  end
  if not lines then
    local stat, err = vim.uv.fs_stat(path)
    if not stat then
      return { '[Cannot read file: ' .. tostring(err):gsub('[%c]', ' ') .. ']' }
    end
    if stat.type ~= 'file' then
      return { '[Not a regular file]' }
    end
    if stat.size > max_bytes then
      return { '[File exceeds 1 MiB preview limit]' }
    end
    local fd, open_err = vim.uv.fs_open(path, 'r', 438)
    if not fd then
      return { '[Cannot read file: ' .. tostring(open_err):gsub('[%c]', ' ') .. ']' }
    end
    local data, read_err = vim.uv.fs_read(fd, max_bytes, 0)
    vim.uv.fs_close(fd)
    if not data then
      return { '[Cannot read file: ' .. tostring(read_err):gsub('[%c]', ' ') .. ']' }
    end
    if data:find('\0', 1, true) then
      return { '[Binary file]' }
    end
    lines = vim.split(data, '\n', { plain = true })
    if #lines > 1 and lines[#lines] == '' then
      table.remove(lines)
    end
  end
  local result = {}
  for i = 1, math.min(#lines, max_lines) do
    local line = lines[i] or ''
    if line:find('\0', 1, true) or line:find('\n', 1, true) then
      return { '[Binary file]' }
    end
    line = line:gsub('\r$', '')
    if vim.fn.strchars(line) > max_line_length then
      line = vim.fn.strcharpart(line, 0, max_line_length) .. '…'
    end
    result[#result + 1] = line
  end
  if truncated or #lines > max_lines then
    result[#result + 1] = '[Preview limited to 2000 lines]'
  end
  return result, ft or vim.filetype.match({ filename = path })
end

---@param parent integer
local function layout(parent)
  local pos = vim.api.nvim_win_get_position(parent)
  local col = pos[2] + vim.api.nvim_win_get_width(parent) + 1
  local width = math.min(80, vim.o.columns - col - 2)
  local height = math.min(30, vim.api.nvim_win_get_height(parent) - 2)
  if width < 20 or height < 3 then
    return
  end
  return {
    relative = 'editor',
    row = pos[1],
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 40,
  }
end

---@param parent integer
---@param entry vimrc.explorer.Entry?
function Preview:update(parent, entry)
  if not self.enabled or not entry or entry.dir then
    self:hide()
    return
  end
  local config = layout(parent)
  if not config then
    self:hide()
    return
  end
  if self.path == entry.path and self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_set_config(self.win, config)
    return
  end
  self:hide()
  local generation = self.generation
  local path = entry.path
  vim.defer_fn(function()
    if self.generation ~= generation or not vim.api.nvim_win_is_valid(parent) then
      return
    end
    local lines, ft = content(path)
    local buf = vim.api.nvim_create_buf(false, true)
    self.buf, self.path = buf, path
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'vimrc-explorer-preview'
    vim.bo[buf].swapfile = false
    vim.b[buf].completion = false
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    config.title = ' ' .. vim.fs.basename(path):gsub('[%c]', ' ') .. ' '
    self.win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[self.win].number = true
    if ft and ft ~= '' then
      vim.bo[buf].syntax = ft
      pcall(vim.treesitter.start, buf, vim.treesitter.language.get_lang(ft) or ft)
    end
  end, 80)
end

---@param delta integer
function Preview:scroll(delta)
  local win = self.win
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_call(win, function()
      local key = delta > 0 and '<C-d>' or '<C-u>'
      vim.cmd.normal({
        args = { vim.api.nvim_replace_termcodes(key, true, false, true) },
        bang = true,
      })
    end)
  end
end

return M
