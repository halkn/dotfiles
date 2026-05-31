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

3. Make zsh the default shell. apt registers it in `/etc/shells`, so `chsh`
   accepts it directly. This only rewrites the login shell entry (it does
   not read `.zshrc`), so order relative to the bootstrap does not matter;
   it takes effect on the next login.

   ```sh
   chsh -s "$(command -v zsh)"
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
   etc.) and installs the Nix tools.

   ```sh
   just setup
   ```

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config.

zsh keeps its config under `.config/zsh` (XDG); the only file in `$HOME` is
a small `.zshenv` stub that sets `ZDOTDIR` and hands off to it. Put
machine-local settings in `.config/zsh/.zshenv.local` (environment) or
`.config/zsh/.zshrc.local` (interactive); both are gitignored.

### Git identity

The git config (`$XDG_CONFIG_HOME/git/config`) includes a relative
`config.local` sibling, which resolves under `$XDG_CONFIG_HOME` and is not
tracked here. Set your name and email there per machine:

```sh
git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.name "Your Name"
git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.email "you@example.com"
```

Verify the effective identity (this reads the included `config.local`):

```sh
git config user.name && git config user.email
```

## Tool Manager

Most CLI tools and zsh plugins are managed by [Nix](https://nixos.org) via
`flake.nix`, and `just setup` / `just update` keep them in sync.

Useful tasks:

```sh
just          # List tasks
just setup    # Link dotfiles and install Nix tools
just update   # Update Nix tools (flake.lock)
just fmt      # Format Markdown, zsh files, and Neovim Lua files
just fmt-check # Check formatting without writing files
just lint     # Run repository checks
```
