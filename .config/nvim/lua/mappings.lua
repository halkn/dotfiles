vim.g.mapleader = [[ ]]
vim.g.maplocalleader = [[,]]

local map = function(mode, lhs, rhs)
  local opts = { silent = false, noremap = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end
local remap = function(mode, lhs, rhs)
  local opts = { silent = false, remap = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Improve Multi Line Move
map('n', 'k', 'gk')
map('n', 'j', 'gj')
map('n', 'gj', 'j')
map('n', 'gk', 'k')

-- Improve Cursor Move in Normal,Visial-Mode
map({ 'n', 'v' }, 'H', '^')
map({ 'n', 'v' }, 'L', '$')

-- Improve Cursor Move in Insert-Mode (emacs like)
map('i', '<C-b>', '<Left>')
map('i', '<C-f>', '<Right>')
map('i', '<C-a>', '<C-o>^')
map('i', '<C-e>', '<End>')
map('i', '<C-d>', '<Del>')

-- Improve Cursor Move in Cmdline-Mode (emacs like)
map('c', '<C-b>', '<Left>')
map('c', '<C-f>', '<Right>')
map('c', '<C-a>', '<HOME>')
map('c', '<C-e>', '<END>')

-- Improve Operation for Window
map('n', '<Tab>', '<C-w>w')
map('n', '<S-Tab>', '<C-w>W')
map('n', '<Left>', '5<C-w><')
map('n', '<Right>', '5<C-w>>')
map('n', '<Up>', '2<C-w>+')
map('n', '<Down>', '2<C-w>-')
map('n', '<C-q>', '<cmd>q<CR>')
map('i', '<C-q>', '<cmd>q<CR><Esc>')
map('t', '<C-q>', '<cmd>q!<CR>')

-- Improve Yank for delete operation
map({ 'n', 'x' }, 'x', '\"_x')
map({ 'n', 'x' }, 'X', '\"_X')

-- Does not move when using *
map('n', '*', '*N')

-- Indent in visual and select mode automatically re-selects.
map('v', '>', '>gv')
map('v', '<', '<gv')

-- Disable dangerous key
map('n', 'ZZ', '<Nop>')
map('n', 'ZQ', '<Nop>')

-- Clear search highlight
map('n', '<Esc><Esc>', '<cmd>nohlsearch<CR><Esc>')
map('n', '<C-l>', '<cmd>nohlsearch<CR><C-l>')

-- To'n', ggle options
map('n', '<Leader>on', '<cmd>setlocal number! number?<CR>')
map('n', '<Leader>or', '<cmd>setlocal relativenumber! relativenumber?<CR>')
map('n', '<Leader>oc', '<cmd>setlocal cursorline! cursorcolumn!<CR>')
map('n', '<Leader>ow', '<cmd>setlocal wrap! wrap?<CR>')

-- Improve Terminal-Mode
map('t', '<Esc>', '<C-\\><C-n>')
map('t', '<C-y>', '<C-\\><C-n>')
map('n', '<Leader>ts', '<cmd>horizontal terminal<CR>')
map('n', '<Leader>tv', '<cmd>vertical terminal<CR>')
map('n', '<Leader>tt', '<cmd>tab terminal<CR>')
map('n', '<Leader>tw', '<cmd>terminal<CR>')

-- quickfix/loclist
map('n', '[q', '<cmd>cprev<CR>')
map('n', ']q', '<cmd>cnext<CR>')
map('n', '[l', '<cmd>lprevious<CR>')
map('n', ']l', '<cmd>lnext<CR>')

-- commenting
remap({ 'n', 'x', 'o' }, '<Leader>c', 'gcc')
remap('v', '<Leader>c', 'gc')

-- diagnostic
map("n", "<C-e>", vim.diagnostic.open_float)
map("n", "<Leader>d", vim.diagnostic.setqflist)

-- Toggle Terminal
local _term = { buf = nil, win = nil }
local function toggle_terminal()
  if _term.win and vim.api.nvim_win_is_valid(_term.win) then
    vim.api.nvim_win_hide(_term.win)
    _term.win = nil
  else
    local width  = math.floor(vim.o.columns * 0.85)
    local height = math.floor(vim.o.lines * 0.85)
    local row    = math.floor((vim.o.lines - height) / 2)
    local col    = math.floor((vim.o.columns - width) / 2)

    if not _term.buf or not vim.api.nvim_buf_is_valid(_term.buf) then
      _term.buf = vim.api.nvim_create_buf(false, true)
    end

    _term.win = vim.api.nvim_open_win(_term.buf, true, {
      relative = "editor",
      width    = width,
      height   = height,
      row      = row,
      col      = col,
      style    = "minimal",
      border   = "rounded",
    })

    if vim.bo[_term.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
      vim.keymap.set("n", "q", function()
        vim.api.nvim_win_hide(_term.win)
        _term.win = nil
      end, { buffer = _term.buf })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = _term.buf })
    end
    vim.cmd.startinsert()
  end
end
vim.keymap.set({ "n", "t" }, "<C-t>", toggle_terminal, { desc = "Toggle Terminal" })
