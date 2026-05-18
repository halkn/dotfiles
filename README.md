# dotfile

This is my dotfiles.

## Setup

```sh
# Install mise first (see https://mise.jdx.dev/getting-started.html).
curl https://mise.run | sh

# Then run the dotfiles setup task.
just setup
```

## Tool Manager

Tool management is consolidated under [mise](https://mise.jdx.dev) via
`.config/mise/config.toml`. CLI tools, Neovim-required LSP servers, formatters,
and language runtimes are all installed and updated through mise. `just` itself
is managed by mise after the initial bootstrap.

Useful tasks:

```sh
just          # List tasks
just setup    # Link dotfiles, install mise tools, and install zsh plugins
just update   # Update mise tools and zsh plugins
just fmt      # Format Markdown, zsh files, and Neovim Lua files
just fmt-check # Check formatting without writing files
just lint     # Run repository checks
```

## Neovim

Neovim Lua config uses the mise-managed `stylua` for formatting and
`lua-language-server --check` for diagnostics. The shared LuaLS
workspace config lives at `.config/nvim/.luarc.json`.

Core settings are split by responsibility:

- `lua/vimrc/options.lua`: startup options, providers, environment, and grep settings.
- `lua/vimrc/diagnostics.lua`: global `vim.diagnostic.config()`.
- `lua/vimrc/keymaps.lua`: global, LSP-independent keymaps.
- `lua/vimrc/autocmds.lua`: global, LSP-independent autocommands.

LSP language settings keep data boundaries separate from runtime behavior:

- `lua/vimrc/lsp/lang/registry.lua`: static LSP server, efm backend, and formatter definitions.
- `lua/vimrc/lsp/lang/schema.lua`: LuaLS annotations for the LSP language registry.
- `lua/vimrc/lsp/lang/init.lua`: query API derived from the registry.
- `lua/vimrc/lsp/`: shared LSP attach behavior, LSP keymaps, and format-on-save behavior.
- `lsp/*.lua`: Neovim native LSP server configs loaded by `vim.lsp.enable()`.

When changing Neovim Lua settings:

```sh
just fmt
just lint
```

Notes:

- `luals` is not the formatter of record. Keep formatting on `stylua`.
- LSP/formatter execution is configured in the Neovim Lua config; LuaLS owns Lua diagnostics.
- LSP servers and efm backend tools are installed by mise and resolved via
  the shell PATH (mise activate); when running them outside an activated shell,
  use `mise exec -- <tool>` or `mise which <tool>`.
- `rumdl` LSP owns Markdown diagnostics and formatting.
- If `stylua` changes many files, review whether the diff is formatting-only before committing.
