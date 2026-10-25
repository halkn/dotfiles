---@type boolean?
local supported

-- A mise that predates `mise lsp` runs a task named `lsp` instead, and `mise run sync` does not
-- move the mise version, so the command is checked the way `mise lsp --help` documents.
local function has_lsp()
  if supported == nil then
    local ok, result = pcall(function()
      return vim.system({ 'mise', 'help', 'lsp' }, { text = true }):wait()
    end)
    supported = ok
      and result.code == 0
      and (result.stdout or ''):find('Usage: mise lsp', 1, true) ~= nil
  end
  return supported
end

---@type vim.lsp.Config
return {
  cmd = { 'mise', 'lsp' },
  -- mise lsp answers only for the files mise loads as config and ignores other TOML, so it
  -- attaches to every toml buffer.
  filetypes = { 'toml' },
  root_dir = function(bufnr, on_dir)
    if has_lsp() then
      on_dir(
        vim.fs.root(bufnr, { 'mise.toml', '.git' })
          or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      )
    end
  end,
}
