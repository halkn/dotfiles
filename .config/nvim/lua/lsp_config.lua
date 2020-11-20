vim.cmd("packadd nvim-lspconfig")
vim.cmd("packadd completion-nvim")
vim.cmd("packadd nvim-lsputils")
vim.cmd("packadd popfix")


-- nvim-lspconfig
vim.call('sign_define', "LspDiagnosticsErrorSign", {text = "✗", texthl = "LspDiagnosticsError"})
vim.call('sign_define', "LspDiagnosticsWarningSign", {text = "!!", texthl = "LspDiagnosticsWarning"})
vim.call('sign_define', "LspDiagnosticsInformationSign", {text = "●", texthl = "LspDiagnosticsInformation"})
vim.call('sign_define', "LspDiagnosticsHintSign", {text = "▲", texthl = "LspDiagnosticsHint"})

local nvim_lsp = require('lspconfig')
local completion = require('completion')

local custom_attach = function(client)
  completion.on_attach({
    client,
    sorting = 'none',
    auto_change_source = 1,
    trigger_on_delete = 1,
  })

  local mapper = function(mode, key, result)
    vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap=true, silent=true})
  end

  mapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', 'gD', '<Cmd>vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  mapper('n', 'gr', '<cmd>lua require"telescope.builtin".lsp_references{}<CR>')
  mapper('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>')
  mapper('n', '<LocalLeader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  mapper('n', '<LocalLeader>s', '<cmd>lua require"telescope.builtin".lsp_document_symbols{}<CR>')
  mapper('n', '<LocalLeader>w', '<cmd>lua require"telescope.builtin".lsp_workspace_symbols{}<CR>')
  mapper('n', '<LocalLeader>m', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('n', '<LocalLeader>sl', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")
end

-- go
nvim_lsp.gopls.setup{
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true
        }
      }
    }
  },
  init_options = {
    usePlaceholders=true;
    linkTarget="pkg.go.dev";
    completionDocumentation=true;
    completeUnimported=true;
    deepCompletion=true;
    staticcheck=true;
  },
  on_attach=custom_attach
}

-- Synchronously organise (Go) imports.
function Go_organize_imports_sync(timeout_ms)
  vim.lsp.buf.formatting_sync(nil, 1000)
  local context = { source = { organizeImports = true } }
  vim.validate { context = { context, 't', true } }
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
  if not result then return end
  result = result[1].result
  if not result then return end
  local edit = result[1].edit
  vim.lsp.util.apply_workspace_edit(edit)
end

vim.api.nvim_command("augroup vimrc_go_org_imports")
vim.api.nvim_command("au!")
vim.api.nvim_command("au BufWritePre *.go lua Go_organize_imports_sync(1000)")
vim.api.nvim_command("augroup END")

-- bash
nvim_lsp.bashls.setup{
  on_attach=custom_attach
}

-- vim
nvim_lsp.vimls.setup{
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true
        }
      }
    }
  },
  on_attach=custom_attach
}

--json
nvim_lsp.jsonls.setup{
  on_attach=custom_attach
}

-- yaml
nvim_lsp.yamlls.setup{
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
      }
    }
  }
}

-- docker
nvim_lsp.dockerls.setup{
  on_attach=custom_attach
}

--lua
nvim_lsp.sumneko_lua.setup{
  on_attach=custom_attach,
  settings = {
    Lua = {
      diagnostics={
        enable=true,
        globals={
          "vim"
        },
      },
    }
  }
}

-- efm-langserver
nvim_lsp.efm.setup{
  filetypes = {"markdown", "sh"};
}

-- ###########################################################################
-- nvim-lsputils
-- ###########################################################################
vim.lsp.callbacks['textDocument/codeAction'] = require'lsputil.codeAction'.code_action_handler
vim.lsp.callbacks['textDocument/references'] = require'lsputil.locations'.references_handler
vim.lsp.callbacks['textDocument/definition'] = require'lsputil.locations'.definition_handler
vim.lsp.callbacks['textDocument/declaration'] = require'lsputil.locations'.declaration_handler
vim.lsp.callbacks['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler
vim.lsp.callbacks['textDocument/implementation'] = require'lsputil.locations'.implementation_handler
vim.lsp.callbacks['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler
vim.lsp.callbacks['workspace/symbol'] = require'lsputil.symbols'.workspace_handler

-- ###########################################################################
-- completion-nvim
-- ###########################################################################
vim.g.completion_enable_snippet = 'vim-vsnip'
vim.g.completion_confirm_key = '<C-l>'
vim.g.completion_sorting = 'none'

