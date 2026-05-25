# dotfile

This is my dotfiles.

## Structure

- `flake.nix`: inputs and outputs.
  - `homeConfigurations.halkn`: standalone home-manager (WSL Ubuntu / non-NixOS Linux).
- `home/default.nix`: the home-manager module (packages + out-of-store symlinks for
  hand-written configs).

## Setup (standalone home-manager, WSL Ubuntu)

```sh
# 1. Install Nix (multi-user daemon).
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

# 2. Clone the repo to ~/.dotfiles so the out-of-store symlinks resolve.
git clone https://github.com/halkn/dotfiles ~/.dotfiles

# 3. Apply the home-manager config. Flakes are not enabled by default on a
#    fresh Nix install, so enable them for this bootstrap shell via NIX_CONFIG
#    (an env var, not a file, so home-manager can write ~/.config/nix/nix.conf
#    itself). The config persists the setting, so later runs need no flag.
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run home-manager/master -- switch --flake "$HOME/.dotfiles#halkn"

# 4. Make zsh the login shell (home-manager installs it but does not chsh).
chsh -s "$(command -v zsh)"

# 5. Tools not in nixpkgs (markado). zsh plugins come from home-manager.
uv tool install git+https://github.com/halkn/ptm
ptm install
```

Apply later changes with `just switch` (or directly; quote the flake ref because
zsh treats `#` as a glob operator):

```sh
cd ~/.dotfiles && just switch
# equivalently: home-manager switch --flake '.#halkn'
```

## Tool Manager

- **Login shell**: home-manager installs zsh and writes its config, but does not set
  the login shell. Run `chsh -s "$(command -v zsh)"` once on a new machine.
- **Linked configs** (`nvim`, ...):
  [home-manager](https://github.com/nix-community/home-manager) via `home/default.nix`
  links them out-of-store from the repo so they stay editable in place without a rebuild
  (`home-manager switch --flake '.#halkn'`).
- **Managed configs** (`git`, `starship`, `tmux`, `fzf`, `ripgrep`, `eza`, `zsh`): handled
  by their `programs.*` modules. `tmux` and the zsh body under `.config/zsh/` are still
  authored as files (read via `readFile`); the rest, including `starship`, is declared
  inline in Nix (its nerd-font glyphs are built from codepoints via `fromJSON`).
  zsh is a hybrid — history, static aliases, plugins (autosuggestion, fast-syntax-highlighting)
  and the `fzf`/`starship` integrations come from `programs.zsh`, while the hand-written body
  stays in `.config/zsh/.zshrc` (deployed to `$ZDOTDIR` = `~/.config/zsh`).
  These take effect on rebuild (not live-edited like the linked configs).
- **Machine-local overrides** (untracked): the zshrc sources `$ZDOTDIR/.zshrc.local`
  (`~/.config/zsh/.zshrc.local`) if present, and git includes `~/.gitconfig.local`.
  Use these for per-machine PATH, env, aliases, or secrets that should not be committed.
- **Claude Code** (`claude`): the unfree `pkgs.claude-code` in `home.packages`;
  `settings.json`, `CLAUDE.md` and the statusline script stay linked from `claude/`
  so they remain live-editable.
- **Tools not in nixpkgs** (`markado`):
  [halkn/ptm](https://github.com/halkn/ptm) via `ptm install` / `ptm update`.

Useful tasks:

```sh
just           # List tasks
just switch    # Apply the standalone home-manager config
just update    # Update flake inputs, rebuild, and update ptm tools
just setup     # Install ptm tools (markado)
just fmt       # Format Markdown, zsh files, and Neovim Lua files
just fmt-check # Check formatting without writing files
just lint      # Run repository checks
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
