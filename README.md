# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

#### WSL Ubuntu

Install the base packages. `git` / `curl` bootstrap the clone and
installers, `zsh` is the login shell, `unzip` lets mise extract tool
archives, and `bubblewrap` / `socat` are the Claude Code sandbox
prerequisites.

```sh
sudo apt update
sudo apt install -y git curl zsh unzip bubblewrap socat
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

2. Install mise and run the full setup. `mise run setup` (= `mise bootstrap
   --yes`) idempotently clones the zsh plugin repos in `mise.toml`'s
   `[bootstrap.repos]` section, links the dotfiles declared in its
   `[dotfiles]` section, installs mise tools, and installs Claude Code.
   `mise trust` whitelists this repo's `mise.toml` so the tasks are allowed
   to run.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
   mise trust
   mise run setup
   ```

   If a target like `~/.config` already exists as a real directory (not a
   symlink), mise won't overwrite it. Back it up yourself first (e.g.
   `mv ~/.config ~/.config.bak`) — `mise bootstrap --force-dotfiles`
   **overwrites the conflicting files in place with no backup**, unlike the
   old setup script. Use `mise bootstrap --dry-run` or `mise bootstrap
   status` to preview changes beforehand.

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
and dotfiles-specific Neovim tools in `mise.toml`. Both pin exact tool
versions in a `mise.lock` (`mise run update` refreshes it; commit the diff
afterwards). `mise.toml` also declares the dotfiles symlink targets
(`[dotfiles]`) and the zsh plugin repos to clone (`[bootstrap.repos]`:
`zsh-autosuggestions`, `fast-syntax-highlighting`, full git clones under
`$XDG_DATA_HOME/zsh/plugins`), both applied by `mise bootstrap`.
[Claude Code](https://code.claude.com/) is installed standalone.
Task automation uses [mise tasks](https://mise.jdx.dev/tasks/), defined in the
repo's `mise.toml` and run with `mise run`.

Useful tasks:

```sh
mise tasks         # List tasks
mise run setup     # Bootstrap: link dotfiles, clone zsh plugins, install mise tools and Claude Code
mise run update    # Update mise tools, zsh plugins, and Claude Code
mise bootstrap status    # Show what `mise bootstrap` would change
mise run fmt       # Format Markdown, zsh files, and Neovim Lua files
mise run fmt-check # Check formatting without writing files
mise run lint      # Run repository checks
```
