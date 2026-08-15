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

1. Clone the dotfiles. All repositories live under `$REPO_ROOT` (`~/repos`)
   as `<host>/<path>`, so place it at that path.

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

`mise run setup` (= `mise bootstrap --yes --update`) is idempotent. Every
machine-state declaration it converges lives in `mise.toml`: OS packages
(`[bootstrap.packages]`, currently apt-only, so skipped on macOS), zsh plugin
repos (`[bootstrap.repos]`), symlinks (`[dotfiles]`), the login shell
(`[bootstrap.user]`), and the mise tools. Claude Code is installed afterwards.

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

`setup` is for the first run on a machine. Afterwards, `mise run sync` applies
changes to these declarations and `mise run update` moves versions forward; see
[Tool Manager](#tool-manager).

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
split into a portable core and workflows named after what they do:

| Location | Holds |
| --- | --- |
| `.zshrc` | The portable core (history, options, completion, keybindings, aliases) plus lightweight tool setup guarded by `command -v`, so a machine without those tools still gets a working shell |
| `workflows/*.zsh` | Own commands, grouped by the task rather than by the tool: `repo` (`repo`, `dot`), `worktree` (`wt`) |

Splitting by task rather than by tool keeps swapping a backend out of the file
layout. The workflow files also carry no dependency guard at file level: they
define their functions unconditionally and check inside them, because
`.config/herdr/*.sh` sources them by absolute path and a function that never got
defined would fail silently there.

Interactive selection goes through [Television](https://github.com/alexpasmantier/television)
(`tv`). A workflow only owns the picking when it also owns the decision that
follows it — where to cd, what is safe to remove. Everything that is selection
plus one command is a channel instead: `Ctrl-T` completes the current buffer
from the channel matching the command, `Ctrl-R` searches the history, and
channels such as `tv git-log` can be called directly. The configuration and the
channels this repository adds are in `.config/television`.

Machine-local shell settings go in the gitignored `.config/zsh/.zshenv.local`
(environment) and `.zshrc.local` (interactive).

## Git worktree workflow

Parallel work (reviewing several pull requests while developing) uses one
worktree per branch, and inside [herdr](https://herdr.dev) each worktree is a
workspace. The `wt` function in `.config/zsh/workflows/worktree.zsh` is the entry point:

```sh
wt                     # pick a worktree and open it (focus its workspace, or cd)
wt new <branch> [base] # create a branch + worktree and open it
wt pr [<number>]       # pick a pull request and open its head as a worktree
wt rm                  # pick worktrees to remove
wt clean               # remove every merged / upstream-gone worktree
```

Which forge answers `wt pr` (GitHub via `gh`, Azure DevOps via `az repos`) is
decided inside `worktree.zsh`, whose `_forge_*` section is the only place that
knows the difference.

Checkouts are placed under `[worktrees] directory` in
`.config/herdr/config.toml` (`$XDG_DATA_HOME/herdr/worktrees`), so they stay out
of the `$REPO_ROOT` tree that `repo` browses. herdr can create one itself with
`alt+g` and lists them in its `alt+s` picker.

Removal never discards work: `wt rm` refuses what cannot be given back and
deletes local branches with `git branch -d` only, the same rule as the `git pm`
alias. Pull requests from a fork are fetched read-only as `pr-<number>` and are
not pre-trusted for mise, unlike same-repository branches, so treat such a
worktree as untrusted before running its tasks or an agent in it.

Claude Code creates worktrees of its own, so the two kinds are kept apart:

| | `wt` / herdr | Claude Code |
| --- | --- | --- |
| For | branch, pull request and multi-session work a human returns to | isolating a session or a subagent while it runs |
| Created by | `wt new`, `wt pr`, herdr `alt+g` | `--worktree`, `EnterWorktree`, `isolation: worktree` |
| Placed in | `$XDG_DATA_HOME/herdr/worktrees/` | `<repo>/.claude/worktrees/` (gitignored) |
| Removed by | you — `wt rm`, `wt clean`, the `alt+s` picker | Claude Code, on exit or by its periodic sweep |

`wt` marks the second kind with an `agent` flag and leaves it out of
`wt clean`, so reclaiming merged worktrees never races a running agent; it stays
listed in `wt` and `wt rm` for the times a sweep leaves one behind.

## Repositories and herdr workspaces

`repo` (`.config/zsh/workflows/repo.zsh`) picks a repository under `$REPO_ROOT`
(`~/repos`) and cd's into it; `repo get <owner/repo|url>` clones one
and cd's into the clone.

Clones are placed at `$REPO_ROOT/<host>/<path>`, with the forge-specific
spellings of one repository folded onto a single directory (`repo.zsh` holds the
normalization rules). The listing is a depth-bounded glob over that layout, so a
repository placed at another depth is not picked up.

The same listing backs herdr's `alt+w`, which picks a repository and creates a
workspace with it as the cwd in one step; `alt+shift+w` is the plain "new
workspace in the current directory".

Outside a herdr session everything degrades to plain `git worktree` plus `cd`.

## Tool Manager

CLI tools, LSP servers, and formatters are managed by
[mise](https://mise.jdx.dev/), and the declaration goes where the tool is
called from: anything invoked from an arbitrary directory — the shell, the LSP
servers and formatters Neovim starts per filetype, checks meant to run in every
repository — is declared in `.config/mise/config.toml`, while tools only this
repository's `mise run` uses (the Lua toolchain) stay in `mise.toml`.
[Claude Code](https://code.claude.com/) is the one exception installed
standalone, because its own installer is the supported path and it should
always be on the latest version.

Each configuration root has its own lockfile: `.config/mise/mise.lock` for
the shared global tools and `mise.lock` for dotfiles-specific tools. Both are
committed, and only `mise run update` is allowed to move the versions in them
— `mise run setup` and `mise run sync` install what the lockfiles already pin.
A lockfile diff after `update` is the update itself; commit it. A lockfile diff
after `setup` or `sync` means a newly declared tool had no locked version yet,
so commit that too.

mise shell activation uses PATH mode rather than shims. Keep shell aliases and
functions in zsh; use mise's `[env]` only for project-specific environments.
Machine-local overrides go in the gitignored `config.local.toml` (global) or
`mise.local.toml` (per repository), which may override `[env]`, `[tools]`, and
settings without changing the shared configuration.

Task automation uses [mise tasks](https://mise.jdx.dev/tasks/), defined in the
repo's `mise.toml` and run with `mise run` (`mise tasks` lists them).

The three machine-state tasks are separated by the state transition they make,
not by the commands they happen to run:

| Task | Use it when | Moves versions | Touches machine-global state |
| --- | --- | --- | --- |
| `setup` | this machine has never been set up | zsh plugin repos only (they are unpinned, and on a first run they are being cloned) | yes — OS packages, login shell, symlinks |
| `sync` | this repo changed (here or on another machine) and the machine should follow | no — tools come from the lockfiles | yes, the same set, by converging on the new declarations |
| `update` | a tool or external component should move to a newer version | yes — that is its purpose | yes, but only versions of what is already declared |

`setup` and `sync` both run the full `mise bootstrap` rather than `mise install`
alone, because any declaration can have changed — a symlink in `[dotfiles]`, an
OS package, a zsh plugin repo — and installing tools alone would leave the rest
of the machine on the previous declaration. Both converge, so re-running them
changes nothing once the machine matches.

`update` never pulls this repo: run `sync` first if you want the current
declarations, then `update`, then commit the lockfile diffs. Its steps are
independent — a failing step is reported, the rest still run, and the task exits
non-zero listing every failure.

Repository quality tasks (`fmt`, `lint`) touch no machine state and are separate
from all of the above; `mise tasks` lists them.

## Neovim plugins

Neovim plugins are managed by the built-in `vim.pack`; their lockfile is
`.config/nvim/nvim-pack-lock.json` and must be committed with plugin updates.
Do not edit the lockfile manually.

`vim.pack` is a Lua API only, so `.config/nvim/lua/vimrc/pack.lua` wraps it in
the commands below. Drop them once Neovim ships equivalent built-in commands.

- Update plugins with `:PackUpdate`, review the resulting buffer, then use
  `:write` to confirm or `:quit` to discard. Run `:restart` when the updated
  code must be loaded immediately.
- Inspect available updates without downloading with `:PackUpdate offline`.
- On another machine, pull the lockfile and `:restart` to install the missing
  plugins, then run `:PackUpdate lockfile` to align the rest with the lockfile.
- To remove a plugin, delete its specification, `:restart`, then run
  `:PackClean` to delete every plugin that is no longer specified.
- To reinstall a plugin, run `:PackReinstall {name}`.
