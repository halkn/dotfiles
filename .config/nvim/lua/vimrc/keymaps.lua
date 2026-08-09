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

-- Move by display line, keeping the real-line motions on gj/gk.
map('n', 'k', 'gk')
map('n', 'j', 'gj')
map('n', 'gj', 'j')
map('n', 'gk', 'k')

map({ 'n', 'v' }, 'H', '^')
map({ 'n', 'v' }, 'L', '$')

-- Emacs-style motions in insert mode
map('i', '<C-b>', '<Left>')
map('i', '<C-f>', '<Right>')
map('i', '<C-a>', '<C-o>^')
map('i', '<C-e>', '<End>')
map('i', '<C-d>', '<Del>')

-- Emacs-style motions in cmdline mode
map('c', '<C-b>', '<Left>')
map('c', '<C-f>', '<Right>')
map('c', '<C-a>', '<HOME>')
map('c', '<C-e>', '<END>')

-- Window
map('n', '<Tab>', '<C-w>w')
map('n', '<S-Tab>', '<C-w>W')
map('n', '<Left>', '5<C-w><')
map('n', '<Right>', '5<C-w>>')
map('n', '<Up>', '2<C-w>+')
map('n', '<Down>', '2<C-w>-')
map('n', '<C-q>', '<cmd>q<CR>')
map('i', '<C-q>', '<cmd>q<CR><Esc>')
map('t', '<C-q>', '<cmd>q!<CR>')

-- Single-character deletes should not clobber the unnamed register.
map({ 'n', 'x' }, 'x', '"_x')
map({ 'n', 'x' }, 'X', '"_X')

-- Highlight the word under the cursor without jumping to the next match.
map('n', '*', '*N')

-- Keep the selection after indenting so the operator can be repeated.
map('v', '>', '>gv')
map('v', '<', '<gv')

-- ZZ / ZQ are one keystroke away from a quit with no confirmation.
map('n', 'ZZ', '<Nop>')
map('n', 'ZQ', '<Nop>')

-- Clear search highlight
map('n', '<Esc><Esc>', '<cmd>nohlsearch<CR><Esc>')
map('n', '<C-l>', '<cmd>nohlsearch<CR><C-l>')

-- Toggle options
map('n', '<Leader>on', '<cmd>setlocal number! number?<CR>')
map('n', '<Leader>or', '<cmd>setlocal relativenumber! relativenumber?<CR>')
map('n', '<Leader>oc', '<cmd>setlocal cursorline! cursorcolumn!<CR>')
map('n', '<Leader>ow', '<cmd>setlocal wrap! wrap?<CR>')

-- Terminal
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
map('n', '<C-e>', vim.diagnostic.open_float)
map('n', '<LocalLeader>d', vim.diagnostic.setqflist)
