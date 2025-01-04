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
map('n', 'gk', 'k')
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
