local au = vim.api.nvim_create_augroup('vimrc_lint', { clear = true })
return {
  src = 'mfussenegger/nvim-lint',
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {
      lua = { 'selene' },
      markdown = { 'markdownlint-cli2' },
      sh = { 'shellcheck' },
    }

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = au,
      pattern = { '*.lua', '*.md', '*.sh' },
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
