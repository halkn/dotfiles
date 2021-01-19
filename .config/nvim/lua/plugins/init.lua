-- ===========================================================================
-- utility function
-- ===========================================================================
local bmapper = function(mode, key, result)
  vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap=true, silent=true})
end

local nmap = function(key, result)
  vim.fn.nvim_set_keymap('n', key, result, {noremap=true, silent=true})
end

-- ===========================================================================
-- treesitter
-- ===========================================================================
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
  },
}

-- ===========================================================================
-- telescope
-- ===========================================================================
-- local actions = require('telescope.actions')
-- require('telescope').setup {
--   defaults = {
--     prompt_position = "top",
--     sorting_strategy = "ascending",
--     layout_strategy = "flex",
--     generic_sorter = require'telescope.sorters'.get_fzy_sorter,
--     file_sorter = require'telescope.sorters'.get_fzy_sorter,
--     vimgrep_arguments = {
--       'rg',
--       '--color=never',
--       '--no-heading',
--       '--with-filename',
--       '--line-number',
--       '--column',
--       '--smart-case',
--       '--hidden'
--     },
--     mappings = {
--       i = {
--         ["<C-j>"] = actions.move_selection_next,
--         ["<C-k>"] = actions.move_selection_previous,
--         ["<esc>"] = actions.close,
--       },
--     },
--   }
-- }
-- 
-- nmap('<Leader>f',  '<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>')
-- nmap('<Leader>b',  '<cmd>Telescope buffers<CR>')
-- nmap('<Leader>R',  '<cmd>Telescope live_grep<CR>')
-- nmap('<Leader>q',  '<cmd>Telescope quickfix<CR>')
-- nmap('<Leader>ml', '<cmd>Telescope find_files cwd=~/memo<CR>')
-- nmap('<Leader>gs', '<cmd>Telescope git_status<CR>')
-- nmap('<Leader>gl', '<cmd>Telescope git_commits<CR>')

-- ===========================================================================
-- gitsigns.nvim
-- ===========================================================================
require('gitsigns').setup {
  signs = {
    add          = {hl = 'GitGutterAdd'   , text = '+'},
    change       = {hl = 'GitGutterChange', text = '!'},
    delete       = {hl = 'GitGutterDelete', text = '_'},
    topdelete    = {hl = 'GitGutterDelete', text = '‾'},
    changedelete = {hl = 'GitGutterChangeDelete', text = '~'},
  },
  keymaps = {
    noremap = true,
    buffer = true,
    ['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
    ['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},
    ['n <leader>ga'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
    ['n <leader>gr'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
    ['n <leader>gu'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
    ['n <leader>gp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
  },
  watch_index = {
    interval = 1000
  },
  sign_priority = 6,
  status_formatter = nil, -- Use default
}

-- ===========================================================================
-- nvim-lspconfig
-- ===========================================================================
vim.cmd("sign define LspDiagnosticsSignError text=✗  texthl=LspDiagnosticsSignError linehl= numhl=")
vim.cmd("sign define LspDiagnosticsSignWarning text=!! texthl=LspDiagnosticsSignWarning linehl= numhl=")
vim.cmd("sign define LspDiagnosticsSignInformation text=● texthl=LspDiagnosticsSignInformation linehl= numhl=")
vim.cmd("sign define LspDiagnosticsSignHint text=▲ texthl=LspDiagnosticsSignHint linehl= numhl=")

local nvim_lsp = require('lspconfig')
local custom_attach = function()
  bmapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  bmapper('n', 'gD', '<Cmd>vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>')
  bmapper('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
  bmapper('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  bmapper('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  bmapper('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  bmapper('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>')
  bmapper('n', '<LocalLeader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  bmapper('n', '<LocalLeader>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  bmapper('n', '<LocalLeader>w', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  bmapper('n', '<LocalLeader>m', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  bmapper('n', '<LocalLeader>sl', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")
end

local cap = {
  textDocument = {
    completion = {
      completionItem = {
        snippetSupport = true
      }
    }
  }
}
-- go
nvim_lsp.gopls.setup{
  capabilities = cap,
  cmd = {"gopls", "serve"},
  settings = {
    gopls = {
      usePlaceholders=true,
      gofumpt = true,
      analyses = {
        unusedparams = true,
      }
    },
  },
  on_attach=custom_attach
}

-- Synchronously organise (Go) imports.
function goimports(timeoutms)
  local context = { source = { organizeImports = true } }
  vim.validate { context = { context, "t", true } }

  local params = vim.lsp.util.make_range_params()
  params.context = context

  local method = "textDocument/codeAction"
  local resp = vim.lsp.buf_request_sync(0, method, params, timeoutms)
  if resp and resp[1] then
    local result = resp[1].result
    if result and result[1] then
      local edit = result[1].edit
      vim.lsp.util.apply_workspace_edit(edit)
    end
  end

  vim.lsp.buf.formatting()
end

vim.api.nvim_command("augroup vimrc_go_org_imports")
vim.api.nvim_command("au!")
vim.api.nvim_command("au BufWritePre *.go lua goimports(1000)")
vim.api.nvim_command("augroup END")

-- bash
nvim_lsp.bashls.setup{
  on_attach=custom_attach
}

-- vim
nvim_lsp.vimls.setup{
  capabilities = cap,
  on_attach=custom_attach
}

--json
nvim_lsp.jsonls.setup{
  on_attach=custom_attach
}

-- yaml
nvim_lsp.yamlls.setup{
  capabilities = cap,
  on_attach=custom_attach,
  settings = {
    yaml = {
      schemas = {
        ['https://json.schemastore.org/cloudbuild'] = 'cloudbuild*.yaml',
        ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
      },
      format = {
        enable = true,
        singleQuote = true
      },
      completion = true,
    }
  }
}

-- docker
nvim_lsp.dockerls.setup{
  capabilities = cap,
  on_attach=custom_attach
}

--lua
nvim_lsp.sumneko_lua.setup{
  on_attach=custom_attach,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';'),
      },
      diagnostics={
        enable=true,
        globals={
          "vim"
        },
      },
      workspace = {
        library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        },
      },
    }
  }
}

-- efm-langserver
nvim_lsp.efm.setup{
  filetypes = {"markdown", "sh"};
}

-- ===========================================================================
-- fzf_lsp
-- ===========================================================================
require'fzf_lsp'.setup()

-- ===========================================================================
-- nvim-lsputils
-- ===========================================================================
-- local border_chars = {
--   TOP_LEFT = '┌',
--   TOP_RIGHT = '┐',
--   MID_HORIZONTAL = '─',
--   MID_VERTICAL = '│',
--   BOTTOM_LEFT = '└',
--   BOTTOM_RIGHT = '┘',
-- }
-- vim.g.lsp_utils_location_opts = {
--   height = 12,
--   mode = 'editor',
--   preview = {
--     title = 'Location Preview',
--     border = true,
--     border_chars = border_chars
--   },
--   list = {
--     border = true,
--     border_chars = border_chars
--   },
--   keymaps = {
--     n = {
--       ['<C-n>'] = 'j',
--       ['<C-p>'] = 'k',
--     }
--   },
-- }
-- vim.g.lsp_utils_symbols_opts = {
--   height = 24,
--   mode = 'editor',
--   preview = {
--     title = 'Symbols Preview',
--     border = true,
--     border_chars = border_chars
--   },
--   list = {
--     border = true,
--     border_chars = border_chars
--   },
--   prompt = {
--     border_chars = border_chars
--   },
-- }
-- vim.lsp.callbacks['textDocument/codeAction'] = require'lsputil.codeAction'.code_action_handler
-- vim.lsp.callbacks['textDocument/references'] = require'lsputil.locations'.references_handler
-- vim.lsp.callbacks['textDocument/definition'] = require'lsputil.locations'.definition_handler
-- vim.lsp.callbacks['textDocument/declaration'] = require'lsputil.locations'.declaration_handler
-- vim.lsp.callbacks['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler
-- vim.lsp.callbacks['textDocument/implementation'] = require'lsputil.locations'.implementation_handler
-- vim.lsp.callbacks['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler
-- vim.lsp.callbacks['workspace/symbol'] = require'lsputil.symbols'.workspace_handler
