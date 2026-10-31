---@type vimrc.lsp.Config
local config = {
  -- The rustup proxy, so the server follows the project's rust-toolchain.toml.
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  -- Cargo.lock first: it sits at the workspace root, while Cargo.toml is also in every member.
  root_markers = { 'Cargo.lock', 'rust-project.json', 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      check = {
        command = 'clippy',
      },
    },
  },
}

return config
