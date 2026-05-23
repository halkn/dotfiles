# dotfile

This is my dotfiles.

## Structure

- `flake.nix`: inputs and outputs.
  - `nixosConfigurations.wsl`: NixOS-WSL host (system + home-manager module + zsh login shell).
  - `homeConfigurations.halkn`: standalone home-manager for non-NixOS Linux.
- `home/default.nix`: shared home-manager module (packages + out-of-store symlinks for
  hand-written configs). Reused by both outputs.
- `hosts/wsl/configuration.nix`: NixOS-WSL system settings (wsl, zsh login shell, timezone, stateVersion).

## Setup (NixOS-WSL)

```sh
# 1. On Windows (PowerShell), import NixOS-WSL using the release `nixos.wsl`:
#    wsl --install --from-file nixos.wsl

# 2. First boot (default `nixos` user): build the system from this flake.
#    `boot` avoids activating while logged in as the about-to-be-removed user;
#    `--no-write-lock-file` is required because the GitHub flake is read-only.
sudo nixos-rebuild boot --flake "github:halkn/dotfiles#wsl" --no-write-lock-file

# 3. On Windows, `wsl --shutdown`, then reopen — you log in as `halkn` with zsh.

# 4. Clone the repo to ~/.dotfiles so the out-of-store symlinks resolve and
#    you can rebuild locally.
git clone https://github.com/halkn/dotfiles ~/.dotfiles

# 5. Tools not in nixpkgs (claude, markado). zsh plugins come from home-manager.
uv tool install git+https://github.com/halkn/ptm
ptm install
```

Apply later changes with `just switch` (or directly; quote the flake ref because
zsh treats `#` as a glob operator):

```sh
cd ~/.dotfiles && just switch
# equivalently: sudo nixos-rebuild switch --flake '.#wsl'
```

## Setup (standalone home-manager, non-NixOS Linux)

```sh
# 1. Install Nix (multi-user daemon).
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

# 2. Clone and apply the home-manager config.
git clone https://github.com/halkn/dotfiles ~/.dotfiles
nix run home-manager/master -- switch --flake "$HOME/.dotfiles#halkn" \
  --extra-experimental-features 'nix-command flakes'

# 3. Tools not in nixpkgs (zsh plugins come from home-manager).
uv tool install git+https://github.com/halkn/ptm
ptm install
```

## Tool Manager

- **System / login shell / WSL settings** (NixOS-WSL only): `hosts/wsl/configuration.nix`,
  applied by `nixos-rebuild`.
- **CLI tools + dotfile symlinks**:
  [home-manager](https://github.com/nix-community/home-manager) via `home/default.nix`.
  Packages live in `home.packages`; hand-written configs (`nvim`, `zsh`, `zellij`,
  `ripgrep`, ...) are linked out-of-store so they stay editable in place. On NixOS-WSL
  home-manager runs as a NixOS module (applied by `nixos-rebuild`); elsewhere it runs
  standalone (`home-manager switch --flake '.#halkn'`).
- **Generated configs** (`git`, `starship`, `tmux`): managed by their `programs.*`
  modules in `home/default.nix`. `starship`/`tmux` are still authored as files under
  `.config/` and read in via `fromTOML`/`readFile`; `git` is fully declared in Nix.
- **Tools not in nixpkgs** (`claude`, `markado`):
  [halkn/ptm](https://github.com/halkn/ptm) via `ptm install` / `ptm update`.
- **zsh plugins** (autosuggestions, fast-syntax-highlighting): declared in `home/default.nix`
  via `xdg.dataFile`, linked from nixpkgs into the dir `.zshrc` already sources.

Useful tasks:

```sh
just           # List tasks
just switch    # Apply the NixOS-WSL system + home-manager config
just update    # Update flake inputs, rebuild, and update ptm tools
just setup     # Install ptm tools (claude, markado)
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
