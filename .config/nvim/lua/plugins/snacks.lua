---@type LazySpec
local spec = {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      { "<leader>f", function() Snacks.picker.files({ hidden = true }) end,    desc = "Find Files" },
      { "<leader>b", function() Snacks.picker.buffers() end,                   desc = "Buffers" },
      { "<leader>l", function() Snacks.picker.lines() end,                     desc = "Buffer Lines" },
      { "<leader>G", function() Snacks.picker.grep({ hidden = true }) end,     desc = "Grep" },
      { "<leader>e", function() Snacks.picker.explorer({ hidden = true }) end, desc = "Explorer" },
      { "<c-t>",     function() Snacks.terminal() end,                         desc = "Toggle Terminal", mode = { "n", "t" } },
    },
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      ---@class snacks.dashboard.Config
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files({ hidden = true })" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.dashboard.pick('projects')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
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
      terminal = {
        enabled = true,
        win = { position = "float", },
      },
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
              desc = "escape to normal mode",
            },
          },
        }
      },
      words = { enabled = true },
    },
  }
}

return spec
