# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

#### WSL Ubuntu

1. Enable systemd so the multi-user Nix daemon can run. Confirm
   `/etc/wsl.conf`; if the `[boot]` section is missing, add it, then run
   `wsl.exe --shutdown` from Windows and reopen the distribution. Recent
   WSL on Ubuntu 26.04 enables it by default.

   ```ini
   # /etc/wsl.conf
   [boot]
   systemd=true
   ```

2. Install the apt packages. `git` and `curl` are normally already present
   (`git` clones the repo, `curl` fetches the Nix installer), `zsh` is the
   login shell, and `bubblewrap` and `socat` are sandbox prerequisites. The
   rest of the CLI tools come from `flake.nix`.

   ```sh
   sudo apt update
   sudo apt install -y git curl zsh bubblewrap socat
   ```

#### macOS

_To be documented._ macOS skips the systemd step and already ships `zsh`
as the default shell, so only the apt-specific items above differ.

### Bootstrap

Run these on any platform after the prerequisites above.

1. Clone the dotfiles. The setup tasks and symlinks assume the repository
   lives at `~/.dotfiles`.

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/.dotfiles"
   cd "$HOME/.dotfiles"
   ```

2. Install Nix (multi-user), then open a new shell so `nix` is on `PATH`
   (the installer sources its profile from new login shells) and `cd` back
   into the repository.

   ```sh
   sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
   ```

3. Link `.config` and install the Nix tools. Linking first puts
   `.config/nix/nix.conf` in place, which enables the `nix-command` and
   `flakes` features needed by `nix profile install`.

   ```sh
   ln -snfT "$HOME/.dotfiles/.config" "$HOME/.config"
   nix profile install path:.#default
   ```

4. Run the setup task. `just setup` re-links every dotfile (zsh, claude,
   etc.), installs the Nix tools, and installs zsh plugins.

   ```sh
   just setup
   ```

5. Make zsh the default shell, then start a new login shell to load the
   linked `.zshenv` and `.zshrc`.

   ```sh
   chsh -s "$(command -v zsh)"
   ```

## Tool Manager

Most CLI tools are managed by [Nix](https://nixos.org) via `flake.nix`, and
`just setup` / `just update` keep them and the zsh plugins in sync.

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
