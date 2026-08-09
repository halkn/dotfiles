# dotfile

My personal dotfiles for macOS and WSL Ubuntu: zsh, Neovim, Claude Code, and
the CLI tooling around them. Setup, tool versions, and symlink placement are
all driven by mise.

## Setup

Do the platform-specific prerequisites first, then run the common bootstrap.

### Platform prerequisites

On a fresh WSL Ubuntu, only `git` and `curl` are needed before cloning this
repo and installing mise. They are usually preinstalled — check with `git
--version && curl --version`. If either is missing, install it first:

```sh
sudo apt-get update && sudo apt-get install -y git curl
```

macOS needs nothing here — `zsh` is already the default shell, and mise
itself is installed in the bootstrap below.

### Bootstrap

1. Clone the dotfiles. All repositories are managed under `~/repos`
   via ghq, so place it at the ghq-compatible path (ghq itself is
   installed later by mise).

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/repos/github.com/halkn/dotfiles"
   cd "$HOME/repos/github.com/halkn/dotfiles"
   ```

1. Install mise and run the full setup. `mise trust` whitelists this repo's
   `mise.toml` so the tasks are allowed to run.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   mise trust
   mise run setup
   ```

`mise run setup` (= `mise bootstrap --yes --update`) is idempotent and does
the following, all declared in `mise.toml`:

- Refreshes the package-manager metadata, then installs the OS packages in
  `[bootstrap.packages]` (`git`, `curl`, `zsh`, `unzip`, `bubblewrap`,
  `socat`). The current declarations are apt-only, so this step is skipped
  on macOS; other prefixes such as `brew:` are supported when needed.
- Clones the zsh plugin repos in `[bootstrap.repos]`
  (`zsh-autosuggestions`, `fast-syntax-highlighting`) under
  `$XDG_DATA_HOME/zsh/plugins`.
- Links the dotfiles declared in `[dotfiles]`.
- Sets the login shell from `[bootstrap.user]`: registers `/bin/zsh` in
  `/etc/shells` and runs `chsh`.
- Installs the mise tools, then Claude Code.

It may prompt for sudo when refreshing apt metadata or installing packages,
and for your password during `chsh`.

If a target like `~/.config` already exists as a real directory (not a
symlink), mise won't overwrite it. Back it up yourself first (e.g.
`mv ~/.config ~/.config.bak`) — `mise bootstrap --force-dotfiles`
**overwrites the conflicting files in place with no backup**. Use
`mise bootstrap --dry-run` or `mise bootstrap status` to preview changes
beforehand.

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config.

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

## Shell layout

zsh keeps its config under `.config/zsh` (XDG); the only file in `$HOME` is
a small `.zshenv` stub that sets `ZDOTDIR` and hands off to it. `.zshenv`
defines only the shared environment and PATH. Interactive configuration is
split by how strongly it depends on an external CLI:

| Location | Holds |
| --- | --- |
| `.zshrc` | Portable settings (history, options, completion, keybindings, aliases) and overrides for tools that degrade to a standard command when missing, such as `eza` for `ls` or `nvim` for `vim` |
| `integrations/*.zsh` | Setups that need an external CLI and go beyond an alias — `fzf` widgets, `herdr` auto-start. `.zshrc` sources the directory as a glob, and each file checks for its own dependency and returns early, so a new file needs no registration |
| `lib/*.zsh` | Function libraries that other scripts source by absolute path (`wt`, `repo`); moving or renaming them breaks those callers |

zsh history is stored under `$XDG_STATE_HOME/zsh`, while completion and
generated shell-completion files are cached under `$XDG_CACHE_HOME/zsh`.

Put machine-local shell settings in `.config/zsh/.zshenv.local` (environment)
or `.config/zsh/.zshrc.local` (interactive); both are gitignored.

## Git worktree workflow

Parallel work (reviewing several pull requests while developing) uses one
worktree per branch, and inside [herdr](https://herdr.dev) each worktree is a
workspace. The `wt` function in `.config/zsh/lib/worktree.zsh` is the entry point:

```sh
wt                     # pick a worktree and open it (focus its workspace, or cd)
wt new <branch> [base] # create a branch + worktree and open it
wt pr [<number>]       # pick a pull request and open its head as a worktree
wt rm                  # pick worktrees to remove
wt clean               # remove merged / upstream-gone worktrees
```

`wt new` without a base tracks an existing `origin/<branch>` instead of
branching off the default integration branch, so a branch that only exists on
the remote is picked up rather than silently recreated (remote refs are read as
they are; `git fetch` first to see branches added since). `wt pr` uses `gh`, or
`az repos pr` when origin is on Azure DevOps; Azure fork heads are not fetchable
from origin, so those are reported instead of checked out.

Checkouts are placed under `[worktrees] directory` in
`.config/herdr/config.toml` (`~/.local/share/herdr/worktrees`, i.e.
`$XDG_DATA_HOME`), so they stay out of the ghq tree that `repo` browses.
`herdr` itself can also create one with `alt+g`. The `alt+s` picker lists
worktrees to jump to, and removes the selected one with `ctrl-x`; creation is
`wt new` / `wt pr` only.

## Repositories and herdr workspaces

`repo` (`.config/zsh/lib/repo.zsh`) picks a ghq-managed repository with fzf and
cd's into it; `repo get <owner/repo|url>` clones one and cd's into the clone.
The same listing backs `alt+w`, which picks a repository and creates a herdr
workspace with that repository as its cwd, replacing the "create a workspace,
then run `repo` inside it" pair of steps. Plain "new workspace in the current
directory" moved to `alt+shift+w`.

Outside a herdr session everything degrades to plain `git worktree` plus `cd`.

Removal never discards work: `wt rm` skips the main checkout and the worktree
you are standing in, asks again when a worktree is dirty, and deletes the local
branch only with `git branch -d` (merged branches only), the same rule as the
`git pm` alias.

Pull requests from a fork are fetched read-only as `pr-<number>`; run
`gh pr checkout <number>` inside that worktree when you need to push back. Fork
code is not pre-trusted for mise (same-repository branches are), so treat that
worktree as untrusted: inspect it before running its tasks or an agent in it.

## Tool Manager

CLI tools, LSP servers, and formatters are managed by
[mise](https://mise.jdx.dev/): shared tools live in `.config/mise/config.toml`
and dotfiles-specific Neovim tools in `mise.toml`.
[Claude Code](https://code.claude.com/) is installed standalone.

Each configuration root has its own lockfile: `.config/mise/mise.lock` for
the shared global tools and `mise.lock` for dotfiles-specific tools.
`mise run update` refreshes both; commit their diffs afterwards.

mise shell activation uses PATH mode rather than shims. Keep shell aliases and
functions in zsh; use mise's `[env]` only for project-specific environments.
For machine-local global mise overrides, create the gitignored
`.config/mise/config.local.toml`. For a repository-local override, use that
repository's gitignored `mise.local.toml`. These files may override `[env]`,
`[tools]`, and settings without changing the shared configuration.

Task automation uses [mise tasks](https://mise.jdx.dev/tasks/), defined in the
repo's `mise.toml` and run with `mise run`:

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

## Neovim plugins

Neovim plugins are managed by the built-in `vim.pack`; their lockfile is
`.config/nvim/nvim-pack-lock.json` and must be committed with plugin updates.
Do not edit the lockfile manually.

- Update plugins with `:packupdate`, review the resulting buffer, then use
  `:write` to confirm or `:quit` to discard. Restart Neovim when the updated
  code must be loaded immediately.
- Inspect available updates without downloading with `:packupdate ++offline`.
- On another machine, pull the lockfile, restart Neovim, and run
  `:packupdate ++lockfile` to synchronize installed plugins.
- To remove a plugin, delete its specification, restart Neovim, then run
  `:packdel {name}`. Use `:packdel ++all` to remove all inactive plugins.
- To reinstall a plugin, run `:packdel! {name}` and restart Neovim.
