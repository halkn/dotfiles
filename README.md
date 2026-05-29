# dotfile

This is my dotfiles.

## Setup (WSL Ubuntu 26.04)

Bootstraps a fresh WSL Ubuntu 26.04 instance. Run each step in order.

### 0. Enable systemd (required for the Nix daemon)

WSL needs systemd so the multi-user Nix daemon can run. Ubuntu 26.04 on
recent WSL enables it by default; confirm with `cat /etc/wsl.conf`. If the
`[boot]` section below is missing, add it, then restart WSL from Windows
(`wsl.exe --shutdown`) and reopen the distribution.

```ini
# /etc/wsl.conf
[boot]
systemd=true
```

### 1. Install git

`git` and `zsh` are both managed by `flake.nix`, but the repository has to be
cloned (step 2) before Nix exists, so install `git` with apt first. The
flake's `git` becomes the managed version once the tools are installed.

```sh
sudo apt update
sudo apt install -y git
```

`zsh` and the other CLI tools come from `flake.nix`, so no further apt
packages are required. `curl` is normally preinstalled and is used to fetch
the Nix installer in step 3; install it only if missing
(`sudo apt install -y curl`).

### 2. Clone the dotfiles

The setup tasks and symlinks assume the repository lives at `~/.dotfiles`.

```sh
git clone https://github.com/halkn/dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
```

### 3. Install Nix (multi-user)

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Open a new shell afterwards so `nix` is on `PATH` (the installer sources its
profile from new login shells), then return to the repository:

```sh
cd "$HOME/.dotfiles"
```

### 4. Link config and install CLI tools

Linking `.config` first puts `.config/nix/nix.conf` in place, which enables
the `nix-command` and `flakes` features needed by `nix profile install`.

```sh
# Link .config (enables flakes), then install the Nix tool environment
# (includes just, uv, neovim, and the LSP/lint/format tools).
ln -snfT "$HOME/.dotfiles/.config" "$HOME/.config"
nix profile install path:.#default

# Install ptm (for tools not in nixpkgs: claude, markado).
uv tool install git+https://github.com/halkn/ptm
```

### 5. Run the dotfiles setup task

`just setup` re-links every dotfile (zsh, claude, etc.), installs the Nix
tools, runs `ptm install`, and installs zsh plugins. `ptm` lives in
`~/.local/bin`, so put that on `PATH` before running it.

```sh
export PATH="$HOME/.local/bin:$PATH"
just setup
```

### 6. Make zsh the default shell

`zsh` now comes from the Nix profile, so register its path in `/etc/shells`
before `chsh` accepts it.

```sh
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
```

Start a new login shell (or reopen WSL) to pick up the linked `.zshenv` and
`.zshrc`.

## Tool Manager

Most CLI tools are managed by [Nix](https://nixos.org) via `flake.nix`.
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
