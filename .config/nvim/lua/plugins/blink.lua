return {
  src = "saghen/blink.cmp",
  version = "v1.10.1",
  config = function()
    require("blink.cmp").setup({
      keymap = {
        preset = 'super-tab',
      },
      cmdline = { enabled = true },
      appearance = {
        nerd_font_variant = 'mono'
      },
      signature = { enabled = true },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    })
  end
}
