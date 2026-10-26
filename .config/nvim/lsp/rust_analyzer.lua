---@type vimrc.lsp.Config
local config = {
  -- The rustup proxy, so the server comes from the toolchain the project's
  -- rust-toolchain.toml selects, as cargo and rustfmt do.
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  -- Only a workspace root has Cargo.lock, so a member crate opens the whole workspace.
  root_markers = { 'Cargo.lock', 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      check = {
        command = 'clippy',
      },
    },
  },
}

return config
