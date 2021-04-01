local lspconfig = require('lspconfig')
local lfs = require( "lfs" )


-- setup diagnostics
local setup_diagnostics = function()
  vim.api.nvim_exec([[
    sign define LspDiagnosticsSignError text=× texthl=LspDiagnosticsSignError linehl= numhl=
    sign define LspDiagnosticsSignWarning text=⚠ texthl=LspDiagnosticsSignWarning linehl= numhl=
    sign define LspDiagnosticsSignInformation text=Ⓘ texthl=LspDiagnosticsSignInformation linehl= numhl=
    sign define LspDiagnosticsSignHint text= texthl=LspDiagnosticsSignHint linehl= numhl=
  ]], false)

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      signs = true,
      virtual_text = false,
      update_in_insert = false,
    }
  )
end

local setup_servers = function()
  for file in lfs.dir( vim.fn.stdpath("config") .. '/lua/vimrc/lsp/configs/' ) do
    if file ~= "." and file ~= ".." then
      local server =  string.sub(file, 1, string.len(file)- 4)
      local conf = require('vimrc/lsp/configs/' .. server)
      lspconfig[server].setup(conf)
    end
  end
end

local load_lsp = function()
  setup_diagnostics()
  setup_servers()
end

load_lsp()
