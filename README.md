# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

#### WSL Ubuntu

Install the required apt packages. `zsh` is the login shell, and
`bubblewrap` and `socat` are sandbox prerequisites for Claude Code.

```sh
sudo apt update
sudo apt install -y git curl zsh tmux bubblewrap socat unzip
```

`azure-cli` is no longer installed here; mise manages it (see
[Tool Manager](#tool-manager)). Its `azure-devops` extension is added
after the bootstrap (see [Azure CLI extensions](#azure-cli-extensions)).

Make zsh the default shell. apt registers it in `/etc/shells`, so `chsh`
accepts it directly. This only rewrites the login shell entry (it does
not read `.zshrc`), so order relative to the bootstrap does not matter;
it takes effect on the next login.

```sh
chsh -s "$(command -v zsh)"
```

#### macOS

_To be documented._ macOS already ships `zsh` as the default shell, so
only the apt-specific step above differs.

### Bootstrap

Run these on any platform after the prerequisites above.

1. Clone the dotfiles. The setup tasks and symlinks assume the repository
   lives at `~/.dotfiles`.

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/.dotfiles"
   cd "$HOME/.dotfiles"
   ```

2. Run the setup task. `mise run setup` links every dotfile, installs all
   tools, and clones the zsh plugins.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
   mise run setup
   ```

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config.

### Azure CLI extensions

`azure-cli` itself is installed by mise during the bootstrap. After it is
on `PATH`, add the Azure DevOps extension:

```sh
az extension add --name azure-devops
```

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

Most CLI tools are managed by [mise](https://mise.jdx.dev) via
`.config/mise/config.toml`, and `mise run setup` / `mise run update` keep them in sync.
zsh plugins (`zsh-autosuggestions`, `fast-syntax-highlighting`) are managed as
shallow git clones under `$XDG_DATA_HOME/zsh/plugins`.

Useful tasks:

```sh
mise tasks         # List tasks
mise run setup     # Link dotfiles, install mise tools, and clone zsh plugins
mise run update    # Update mise tools and zsh plugins
mise run fmt       # Format Markdown, zsh files, and Neovim Lua files
mise run fmt-check # Check formatting without writing files
mise run lint      # Run repository checks
```
