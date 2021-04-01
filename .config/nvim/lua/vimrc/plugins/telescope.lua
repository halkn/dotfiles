local actions = require('telescope.actions')
require('telescope').setup{
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--hidden',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case'
    },
    prompt_position = "top",
    sorting_strategy = "ascending",
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
      n = {
        ["<esc>"] = actions.close,
      },
    },
    extensions = {
      fzy_native = {
        override_generic_sorter = true,
        override_file_sorter = true,
      }
    }

  }
}

-- ===========================================================================
-- extensions
-- ===========================================================================
require('telescope').load_extension('fzy_native')
require('telescope').load_extension('lsp_handlers')
