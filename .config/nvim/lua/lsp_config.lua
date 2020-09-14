local nvim_lsp = require('nvim_lsp')
local completion = require('completion')

local custom_attach = function(client)
  completion.on_attach({
    client,
    sorting = 'none',
    auto_change_source = 1,
    trigger_on_delete = 1,
  })
  -- require'diagnostic'.on_attach(client)

  local mapper = function(mode, key, result)
    vim.fn.nvim_buf_set_keymap(0, mode, key, result, {noremap=true, silent=true})
  end

  mapper('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>')
  mapper('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  mapper('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  mapper('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>')
  mapper('n', '<LocalLeader>s', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  mapper('n', '<LocalLeader>w', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  mapper('n', '<LocalLeader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  mapper('n', '<LocalLeader>sl', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>')

  vim.cmd("setlocal omnifunc=v:lua.vim.lsp.omnifunc")
end


-- do
--   local method = "textDocument/publishDiagnostics"
--   local default_callback = vim.lsp.callbacks[method]
--   vim.lsp.callbacks[method] = function(err, method, result, client_id)
--     default_callback(err, method, result, client_id)
--     if result and result.diagnostics then
--       for _, v in ipairs(result.diagnostics) do
--         v.uri = v.uri or result.uri
--         v.bufnr = vim.uri_to_bufnr(v.uri)
--         v.lnum = v.range.start.line + 1
--         v.col = v.range.start.character + 1
--         v.text = v.message
--       end
--       vim.lsp.util.set_qflist(result.diagnostics)
--       -- vim.lsp.util.set_loclist(result.diagnostics)
--     end
--   end
-- end

-- go
nvim_lsp.gopls.setup{
  init_options = {
    usePlaceholders=true;
    linkTarget="pkg.go.dev";
    completionDocumentation=true;
    completeUnimported=true;
    deepCompletion=true;
    fuzzyMatching=true;
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
  on_attach=custom_attach
}

--json
nvim_lsp.jsonls.setup{
  on_attach=custom_attach
}

-- yaml
local yamlshemas = {}
yamlshemas["http://json.schemastore.org/cloudbuild"] = "/cloudbuild*.yaml"
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
  filetypes = {"markdown", "json", "sh"};
}
