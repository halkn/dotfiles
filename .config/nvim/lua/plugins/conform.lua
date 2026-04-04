local au = vim.api.nvim_create_augroup("vimrc_conform", { clear = true })
return {
  src = "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        markdown = { "markdownlint-cli2" },
        sh = { "shfmt" }
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = au,
      pattern = { "markdown", "sh" },
      callback = function(ev)
        vim.keymap.set(
          "n",
          "<LocalLeader>f",
          function() require("conform").format({ bufnr = ev.buf }) end,
          { noremap = true, silent = true, buffer = ev.buf }
        )
      end
    })
  end
}
