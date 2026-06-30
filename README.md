# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

#### WSL Ubuntu

Install the base packages. `git` / `curl` bootstrap the clone and
installers, `zsh` is the login shell, `unzip` lets mise extract tool
archives, `xclip` backs Neovim's system clipboard, and `bubblewrap` /
`socat` are the Claude Code sandbox prerequisites.

```sh
sudo apt update
sudo apt install -y git curl zsh unzip xclip bubblewrap socat
```

#### macOS

No extra platform packages are required — macOS already ships `zsh` as the
default shell. mise itself is installed in the bootstrap below.

### Bootstrap

Run these on any platform after the prerequisites above.

1. Clone the dotfiles. All repositories are managed under `~/repos`
   via ghq, so place it at the ghq-compatible path (ghq itself is
   installed later by mise).

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/repos/github.com/halkn/dotfiles"
   cd "$HOME/repos/github.com/halkn/dotfiles"
   ```

2. Install mise and run the full setup. `just setup` creates symlinks
   (`link`), installs mise tools, clones zsh plugins, and installs Claude
   Code in that order. `mise exec` provides a temporary `just` for the
   bootstrap without installing it globally first.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
   mise exec just -- just setup
   ```

3. Make zsh the default login shell. macOS already defaults to zsh; on WSL,
   apt registers zsh in `/etc/shells`, so `chsh` accepts it directly.

   ```sh
   chsh -s "$(command -v zsh)"
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

CLI tools, LSP servers, and formatters are managed by
[mise](https://mise.jdx.dev/): shared tools live in `.config/mise/config.toml`
and dotfiles-specific Neovim tools in `mise.toml`. zsh plugins
(`zsh-autosuggestions`, `fast-syntax-highlighting`) are shallow git clones
under `$XDG_DATA_HOME/zsh/plugins`.
[Claude Code](https://code.claude.com/) is installed standalone.
Task automation uses [just](https://github.com/casey/just) (itself a mise tool).

Useful recipes:

```sh
just --list       # List recipes
just setup        # Link dotfiles, install mise tools and zsh plugins, install Claude Code
just update       # Update mise tools, zsh plugins, and Claude Code
just fmt          # Format Markdown, zsh files, and Neovim Lua files
just fmt-check    # Check formatting without writing files
just lint         # Run repository checks
```
