require('vimrc.options')
require('vimrc.diagnostics')
require('vimrc.keymaps')
require('vimrc.autocmds')
require('vimrc.lsp')

require('vimrc.statusline').setup()

-- pack: load external plugins.
require('vimrc.pack')

-- machine-local overrides (not tracked in git)
pcall(require, 'local')
