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

### 1. Prerequisites

`git` and `curl` are normally already present on Ubuntu: `git` clones this
repository (step 2) and `curl` fetches the Nix installer (step 3). The CLI
tools, including the managed `git` and `zsh`, come from `flake.nix`, so no
apt packages are required on a standard install. Install anything missing:

```sh
sudo apt update
sudo apt install -y git curl
```

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
# (includes just, neovim, and the LSP/lint/format tools).
ln -snfT "$HOME/.dotfiles/.config" "$HOME/.config"
nix profile install path:.#default
```

### 5. Run the dotfiles setup task

`just setup` re-links every dotfile (zsh, claude, etc.), installs the Nix
tools, and installs zsh plugins.

```sh
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

### 7. Install Claude Code

Claude Code releases frequently, so it is installed and updated with its
official installer rather than through Nix.

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

Update it in place with `claude update`.

### 8. Set up the Claude Code sandbox (Linux/WSL2)

Claude Code runs Bash commands in a sandbox for filesystem and network
isolation. On Linux and WSL2 this depends on two packages: `bubblewrap`
(filesystem isolation) and `socat` (network proxy relay).

```sh
sudo apt-get install -y bubblewrap socat
```

The seccomp filter that blocks Unix-domain sockets is optional; install the
helper only if `/sandbox` reports it missing:

```sh
npm install -g @anthropic-ai/sandbox-runtime
```

On Ubuntu 24.04 and later (including 26.04), the default AppArmor policy
stops `bwrap` from creating the user namespaces it needs. Check whether the
restriction is active:

```sh
sysctl kernel.apparmor_restrict_unprivileged_userns
```

If the key is absent or returns `0`, skip the next step. If it returns `1`,
grant `bwrap` the capability and reload AppArmor:

```sh
sudo tee /etc/apparmor.d/bwrap > /dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,
  include if exists <local/bwrap>
}
EOF
sudo systemctl reload apparmor
```

WSL2 notes: sandboxed commands cannot launch Windows binaries (`cmd.exe`,
`powershell.exe`, or anything under `/mnt/c/`); add such commands to
`excludedCommands` to run them outside the sandbox. WSL1 is not supported.

Enable the sandbox with `/sandbox` in a session, or set `sandbox.enabled`
to `true` in `~/.claude/settings.json`. After installing the packages,
restart Claude Code so `/sandbox` detects them.

## Tool Manager

Most CLI tools are managed by [Nix](https://nixos.org) via `flake.nix`, and
`just setup` / `just update` keep them and the zsh plugins in sync. Claude
Code is the exception: it is managed by its own official installer (see
step 7) because it updates frequently.

Useful tasks:

```sh
just          # List tasks
just setup    # Link dotfiles, install Nix tools, and zsh plugins
just update   # Update Nix tools (flake.lock) and zsh plugins
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
