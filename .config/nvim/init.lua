require('vimrc.options')
require('vimrc.diagnostics')
require('vimrc.keymaps')
require('vimrc.autocmds')
require('vimrc.lsp')

require('vimrc.modules.input').setup()
require('vimrc.modules.notify').setup()
require('vimrc.modules.pairs').setup()
require('vimrc.modules.picker').setup()
require('vimrc.modules.replace').setup()
require('vimrc.statusline').setup()
require('vimrc.modules.surround').setup()
require('vimrc.modules.terminal').setup()
require('vimrc.modules.yankring').setup()

-- pack: load external plugins.
require('vimrc.pack')

-- machine-local overrides (not tracked in git)
pcall(require, 'local')
