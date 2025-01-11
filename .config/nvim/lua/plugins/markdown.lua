---@type LazySpec
local spec = {
  {
    "ixru/nvim-markdown",
    ft = "markdown",
    init = function()
      vim.g.vim_markdown_no_default_key_mappings = 1
      vim.g.vim_markdown_conceal = 0

      local group_name = "vimrc_nvim-markdown"
      vim.api.nvim_create_augroup(group_name, { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group_name,
        pattern = { "markdown" },
        callback = function()
          local opts = { noremap = true, silent = true, buffer = true }
          vim.keymap.set("n", "]]", "<Plug>Markdown_MoveToNextHeader", opts)
          vim.keymap.set("n", "[[", "<Plug>Markdown_MoveToPreviousHeader", opts)
          vim.keymap.set("n", "O", "<Plug>Markdown_NewLineAbove", opts)
          vim.keymap.set("n", "o", "<Plug>Markdown_NewLineBelow", opts)
          vim.keymap.set("n", "<LocalLeader>c", "<Plug>Markdown_Checkbox", opts)
          vim.keymap.set("n", "<LocalLeader>a", "<Cmd>Toc<CR>", opts)
          vim.keymap.set("i", "<Enter>", "<Plug>Markdown_NewLineBelow", opts)
          vim.keymap.set({ "i", "x" }, "<C-k>", "<Plug>Markdown_CreateLink", opts)
        end,
      })
    end,
  },

  -- preview
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    init = function()
      local group_name = "vimrc_markdown-preview"
      vim.api.nvim_create_augroup(group_name, { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group_name,
        pattern = { "markdown" },
        callback = function()
          local opts = { noremap = true, silent = true, buffer = true }
          vim.keymap.set("n", "<LocalLeader>p", "<cmd>MarkdownPreviewToggle<CR>", opts)
        end,
      })
    end
  },

}

return spec
