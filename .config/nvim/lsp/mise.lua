-- Only a positive answer is cached, so a mise upgraded while nvim runs is picked up on the next
-- toml buffer.
local supported = false

---@type vim.lsp.Config
return {
  cmd = { 'mise', 'lsp' },
  -- mise lsp answers only for the files mise loads as config and ignores other TOML, so it
  -- attaches to every toml buffer.
  filetypes = { 'toml' },
  root_dir = function(bufnr, on_dir)
    local function attach()
      if vim.api.nvim_buf_is_valid(bufnr) then
        on_dir(vim.fs.root(bufnr, { 'mise.toml', '.git' }))
      end
    end
    if supported then
      attach()
      return
    end
    -- A mise that predates `mise lsp` runs a task named `lsp` instead, and `mise run sync` does
    -- not move the mise version, so the command is checked the way `mise lsp --help` documents.
    -- The check runs asynchronously so that a stuck mise does not block the editor.
    pcall(vim.system, { 'mise', 'help', 'lsp' }, { text = true }, function(result)
      if result.code == 0 and (result.stdout or ''):find('Usage: mise lsp', 1, true) then
        supported = true
        vim.schedule(attach)
      end
    end)
  end,
}
