local au = vim.api.nvim_create_augroup('vimrc_lint', { clear = true })
return {
  src = 'mfussenegger/nvim-lint',
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = require('vimrc.lang').linters_by_ft()

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = au,
      pattern = { '*.zsh', '.zshenv', '.zshrc' },
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
