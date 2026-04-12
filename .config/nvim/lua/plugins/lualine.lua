return {
  src = 'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup({
      options = {
        icons_enabled = true,
        section_separators = '',
        component_separators = '|',
        theme = 'auto',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = {
          'filename',
          {
            function()
              return vim.diagnostic.status()
            end,
            cond = function()
              return vim.diagnostic.status() ~= ''
            end,
          },
        },
        lualine_x = {
          {
            function()
              return vim.ui.progress_status()
            end,
            cond = function()
              return vim.ui.progress_status() ~= ''
            end,
          },
          'encoding',
          'fileformat',
          'filetype',
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    })
  end,
}
