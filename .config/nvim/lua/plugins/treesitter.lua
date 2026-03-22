return {
  src = "nvim-treesitter/nvim-treesitter",
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end
}
