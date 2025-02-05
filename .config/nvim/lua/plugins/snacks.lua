---@type LazySpec
local spec = {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      { "<leader>f", function() Snacks.picker.files({ hidden = true }) end, desc = "Find Files" },
      { "<leader>b", function() Snacks.picker.buffers() end,                desc = "Buffers" },
      { "<leader>l", function() Snacks.picker.lines() end,                  desc = "Buffer Lines" },
      { "<leader>G", function() Snacks.picker.grep({ hidden = true }) end,  desc = "Grep" },
      { "<c-t>",     function() Snacks.terminal() end,                      desc = "Toggle Terminal", mode = { "n", "t" } },
    },
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      ---@class snacks.dashboard.Config
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      ---@class snacks.picker.Config
      picker = {
        enabled = true,
      },
      ---@class snacks.notifier.Config
      notifier = {
        enabled = true,
        style = "fancy"
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = false },
      styles = {
        ---@class snacks.input.Config
        input = {
          relative = "cursor",
        },
        ---@class snacks.terminal.Config
        terminal = {
          keys = {
            q = "hide",
            gf = function(self)
              local f = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
              if f == "" then
                Snacks.notify.warn("No file under cursor")
              else
                self:hide()
                vim.schedule(function()
                  vim.cmd("e " .. f)
                end)
              end
            end,
            term_normal = {
              "<esc>",
              function()
                vim.cmd("stopinsert")
              end,
              mode = "t",
              expr = true,
              desc = "Double escape to normal mode",
            },
          },
        }
      },
      words = { enabled = true },
    },
  }
}

return spec
