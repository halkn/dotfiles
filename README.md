# dotfile

This is my dotfiles.

## Setup

```sh
# 1. Install Nix (multi-user daemon).
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

# 2. Clone this repo to ~/.dotfiles, then apply the home-manager config.
#    Flakes are enabled inline on first run; afterwards ~/.config/nix/nix.conf keeps them on.
nix run home-manager/master -- switch --flake "$HOME/.dotfiles#halkn" \
  --extra-experimental-features 'nix-command flakes'

# 3. Install ptm (for tools not in nixpkgs: claude, markado).
uv tool install git+https://github.com/halkn/ptm

# 4. Run the dotfiles setup task (re-applies home-manager, ptm tools, zsh plugins).
just setup
```

## Tool Manager

CLI tools and dotfile symlinks are managed by
[home-manager](https://github.com/nix-community/home-manager) via `flake.nix`
and `home/default.nix`. The package set lives in `home.packages`, and
hand-written configs (`nvim`, `zsh`, `tmux`, etc.) are linked out-of-store so
they stay editable in place. Apply changes with `home-manager switch --flake .#halkn`.
Tools not available in nixpkgs (`claude`, `markado`) are still managed by
[halkn/ptm](https://github.com/halkn/ptm).

Useful tasks:

```sh
just          # List tasks
just setup    # Link dotfiles, install Nix tools, ptm tools, and zsh plugins
just update   # Update Nix tools (flake.lock), ptm tools, and zsh plugins
just fmt      # Format Markdown, zsh files, and Neovim Lua files
just fmt-check # Check formatting without writing files
just lint     # Run repository checks
```

## Neovim

Neovim Lua config uses the Neovim managed `stylua` for formatting and
the managed `lua-language-server --check` for diagnostics. The shared LuaLS
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
- Neovim-managed LSP servers and efm backend tools live under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools`;
  use absolute paths when running them outside Neovim.
- `rumdl` LSP owns Markdown diagnostics and formatting.
- If `stylua` changes many files, review whether the diff is formatting-only before committing.
