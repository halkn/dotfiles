require'nvim-treesitter.configs'.setup {
  ensure_installed = { "go", "bash", "lua", "typescript" },
  highlight = {
    enable = true,
    disable = { "go" },
  },
  indent = {
    enable = true
  },
}
