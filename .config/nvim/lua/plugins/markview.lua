return {
  src = "halkn/nvim-markview",
  config = function()
    require("markview").setup({
      keymaps = {
        toggle = "<localleader>p",
      },
    })
  end
}
