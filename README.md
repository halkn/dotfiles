# dotfile

This is my dotfiles.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

On a fresh WSL Ubuntu, only `git` and `curl` are needed before cloning this
repo and installing mise. They are usually preinstalled — check with `git
--version && curl --version`. If either is missing, install it first. Every
other declared OS package (`zsh`, `unzip`, `bubblewrap`, and `socat`) and the
login shell are applied by the bootstrap below:

```sh
sudo apt-get update && sudo apt-get install -y git curl
```

macOS needs nothing here — `zsh` is already the default shell, and mise
itself is installed in the bootstrap below.

### Bootstrap

Run these on any platform after the prerequisites above.

1. Clone the dotfiles. All repositories are managed under `~/repos`
   via ghq, so place it at the ghq-compatible path (ghq itself is
   installed later by mise).

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/repos/github.com/halkn/dotfiles"
   cd "$HOME/repos/github.com/halkn/dotfiles"
   ```

1. Install mise and run the full setup. `mise run setup` (= `mise bootstrap
   --yes --update`) refreshes the package-manager metadata first, then
   idempotently installs the OS packages declared in `mise.toml`'s
   `[bootstrap.packages]` section. The current declarations use apt on
   Debian-family Linux; unavailable package managers are skipped. It may ask
   for sudo to refresh apt metadata or install missing packages. The setup
   also clones the zsh plugin repos in
   `[bootstrap.repos]`, links the dotfiles declared in `[dotfiles]`, sets
   the login shell from `[bootstrap.user]` (registers `/bin/zsh` in
   `/etc/shells` and runs `chsh`, which may prompt for your password),
   installs mise tools, and installs Claude Code. `mise trust` whitelists
   this repo's `mise.toml` so the tasks are allowed to run.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   mise trust
   mise run setup
   ```

   If a target like `~/.config` already exists as a real directory (not a
   symlink), mise won't overwrite it. Back it up yourself first (e.g.
   `mv ~/.config ~/.config.bak`) — `mise bootstrap --force-dotfiles`
   **overwrites the conflicting files in place with no backup**, unlike the
   old setup script. Use `mise bootstrap --dry-run` or `mise bootstrap
   status` to preview changes beforehand.

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config.

zsh keeps its config under `.config/zsh` (XDG); the only file in `$HOME` is
a small `.zshenv` stub that sets `ZDOTDIR` and hands off to it. `.zshenv`
defines only the shared environment and PATH; interactive configuration,
including `mise activate zsh`, is in `.zshrc`. zsh history is stored under
`$XDG_STATE_HOME/zsh`, while completion and generated shell-completion files
are cached under `$XDG_CACHE_HOME/zsh`.

Put machine-local shell settings in `.config/zsh/.zshenv.local` (environment)
or `.config/zsh/.zshrc.local` (interactive); both are gitignored.

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
and dotfiles-specific Neovim tools in `mise.toml`. Each configuration root
has its own lockfile: `.config/mise/mise.lock` for the shared global tools
and `mise.lock` for dotfiles-specific tools. `mise run update` refreshes both;
commit their diffs afterwards. `mise.toml` also declares the OS packages
(`[bootstrap.packages]`: apt entries; other manager prefixes like `brew:`
are supported too, and entries for an unavailable manager are skipped
automatically), the login shell
(`[bootstrap.user]`), the dotfiles symlink targets (`[dotfiles]`), and the
zsh plugin repos to clone (`[bootstrap.repos]`: `zsh-autosuggestions`,
`fast-syntax-highlighting`, full git clones under
`$XDG_DATA_HOME/zsh/plugins`), all applied by `mise bootstrap`.
[Claude Code](https://code.claude.com/) is installed standalone.
Task automation uses [mise tasks](https://mise.jdx.dev/tasks/), defined in the
repo's `mise.toml` and run with `mise run`.

mise shell activation uses PATH mode rather than shims. Keep shell aliases and
functions in zsh; use mise's `[env]` only for project-specific environments.
For machine-local global mise overrides, create the gitignored
`.config/mise/config.local.toml`. For a repository-local override, use that
repository's gitignored `mise.local.toml`. These files may override `[env]`,
`[tools]`, and settings without changing the shared configuration.

Useful tasks:

```sh
mise tasks         # List tasks
mise run setup     # Refresh package metadata, then bootstrap OS packages, dotfiles, zsh plugins, login shell, mise tools, and Claude Code
mise run sync      # Fast-forward dotfiles and install the lockfile-pinned mise tools
mise run update    # Update mise itself, tools, both lockfiles, declared OS packages, zsh plugins, and Claude Code
mise bootstrap status    # Show what `mise bootstrap` would change
mise bootstrap packages upgrade  # Upgrade only the declared OS packages
mise run fmt       # Format Markdown, zsh files, and Neovim Lua files
mise run fmt-check # Check formatting without writing files
mise run lint      # Run repository checks
```
