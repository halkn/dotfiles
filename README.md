# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

#### WSL Ubuntu

Install the required apt packages. `bubblewrap` and `socat` are sandbox
prerequisites for Claude Code.

```sh
sudo apt update
sudo apt install -y git curl bubblewrap socat unzip
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az extension add --name azure-devops
```

Install Nix (multi-user):

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

#### macOS

_To be documented._ Install Nix the same way as above. macOS already
ships `zsh` as the default shell.

### Bootstrap

Run these on any platform after the prerequisites above.

1. Clone the dotfiles. The setup tasks and symlinks assume the repository
   lives at `~/.dotfiles`.

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/.dotfiles"
   cd "$HOME/.dotfiles"
   ```

2. Install packages and link dotfiles. `just setup` installs all Nix
   packages, creates symlinks, and installs uv.

   ```sh
   nix profile install nixpkgs#just
   just setup
   ```

3. Set Nix-managed zsh as the default shell.

   ```sh
   echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
   chsh -s "$HOME/.nix-profile/bin/zsh"
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

CLI tools, LSP servers, formatters, and zsh plugins are managed by
[Nix flake](https://nixos.org/) via `nix/packages.nix`.
Task automation uses [just](https://github.com/casey/just).

Useful recipes:

```sh
just --list       # List recipes
just setup        # Link dotfiles, install Nix packages, and install uv
just update       # Update Nix packages and Claude Code
just fmt          # Format Markdown, zsh files, and Neovim Lua files
just fmt-check    # Check formatting without writing files
just lint         # Run repository checks
```
