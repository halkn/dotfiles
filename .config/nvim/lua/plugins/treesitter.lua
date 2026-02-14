---@type LazySpec
local spec = {

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    opts = {
      install_dir = vim.fn.stdpath('data') .. '/site'
    },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
        callback = function(ctx)
          -- 必要に応じて`ctx.match`に入っているファイルタイプの値に応じて挙動を制御
          -- `pcall`でエラーを無視することでパーサーやクエリがあるか気にしなくてすむ
          pcall(vim.treesitter.start)
        end,
      })
    end
  }
}

return spec
