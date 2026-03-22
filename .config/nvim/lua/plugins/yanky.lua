return {
  src = "gbprod/yanky.nvim",
  config = function()
    require("yanky").setup({})
    vim.keymap.set({ "n", "v" }, "p", "<Plug>(YankyPutAfter)")
    vim.keymap.set({ "n", "v" }, "P", "<Plug>(YankyPutBefore)")
    vim.keymap.set({ "n", "v" }, "gp", "<Plug>(YankyGPutAfter)")
    vim.keymap.set({ "n", "v" }, "gP", "<Plug>(YankyGPutBefore)")
    vim.keymap.set({ "n" }, "<c-p>", "<Plug>(YankyPreviousEntry)")
    vim.keymap.set({ "n" }, "<c-n>", "<Plug>(YankyNextEntry)")
    vim.keymap.set({ "n" }, "<Leader>y", "<CMD>YankyRingHistory<CR>")
  end
}
