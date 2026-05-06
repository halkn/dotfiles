local lang = require('vimrc.lsp.lang')

require('vimrc.lsp.attach').setup()

vim.lsp.enable(lang.lsp_servers())
