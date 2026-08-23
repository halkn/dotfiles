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
| `workflows/*.zsh` | Own commands, grouped by the task rather than by the tool: `repo` (`repo`, `dot`), `worktree` (`wt`), `git` (`gst`) |

Splitting by task rather than by tool keeps a backend swap out of the file
layout. The workflow files also carry no dependency guard at file level: they
define their functions unconditionally and check inside them, because
`.config/herdr/*.sh` sources them by absolute path and a function that never got
defined would fail silently there.

Interactive selection goes through [fzf](https://github.com/junegunn/fzf).
A workflow only owns the picking when it also owns the decision that follows it
— where to cd, what is safe to remove, what to stage. Everything that is
selection plus one command is a completion instead: `<command> **<TAB>` picks
the candidates for that command (`git switch`, `git add`, `git log` and paths),
while `Ctrl-R`, `Ctrl-T` and `Alt-C` are fzf's own widgets. The shared options
live in `FZF_DEFAULT_OPTS` and the per-command sources in the `fzf` section of
`.zshrc`.

Machine-local shell settings go in the gitignored `.config/zsh/.zshenv.local`
(environment) and `.zshrc.local` (interactive).

## Git worktree workflow

Parallel work (reviewing several pull requests while developing) uses one
worktree per branch, and inside [herdr](https://herdr.dev) each worktree is a
workspace. The `wt` command lives in `.config/zsh/workflows/nav.zsh`, its
subcommands in `worktree.zsh`. Bare `wt` spans every repository; the subcommands
act on the repository you are standing in:

```sh
wt                     # pick where to go: workspace, worktree, repository or agent
wt new <branch> [base] # create a branch + worktree and open it
wt pr [<number>]       # pick a pull request and open its head as a worktree
wt rm                  # pick worktrees to remove
wt clean               # remove every merged / upstream-gone worktree
```

`wt new` without a base tracks an existing `origin/<branch>` instead of
branching off the default integration branch, so a branch that only exists on
the remote is picked up rather than silently recreated. `wt pr` uses `gh`, or
`az repos pr` when origin is on Azure DevOps; Azure fork heads are not fetchable
from origin, so those are reported instead of checked out.

Which checkouts exist, where a new one belongs, what state each is in and
whether removing one would lose work are all [trepo](https://github.com/halkn/trepo),
configured through `trepo.*` in `.config/git/config` and the global git config.
Checkouts are placed under `trepo.worktreeRoot`
(`~/.local/share/trepo/worktrees`, following XDG), so they stay out of the
`$REPO_ROOT` tree that `repo` browses. The zsh side owns the picker, the row
layout, `cd` and the herdr workspace that follows; it never recomputes a
judgement trepo already makes.

`wt rm` never removes the main checkout, the worktree you are standing in or a
locked one, and holds back anything whose removal needs a decision — uncommitted
changes, ignored files, unpushed commits, a checkout another tool manages —
naming the reason and asking once before it goes ahead. A merged branch is
deleted with `git branch -d` only, the same rule as the `git pm` alias. Pull
requests from a GitHub fork are fetched read-only as `pr-<number>` and are not
pre-trusted for mise, unlike same-repository branches, so treat such a worktree
as untrusted before running its tasks or an agent in it.

Claude Code creates worktrees of its own, so the two kinds are kept apart:

| | `wt` / herdr | Claude Code |
| --- | --- | --- |
| For | branch, pull request and multi-session work a human returns to | isolating a session or a subagent while it runs |
| Created by | `wt new`, `wt pr`, herdr `alt+g` | `--worktree`, `EnterWorktree`, `isolation: worktree` |
| Placed in | `~/.local/share/trepo/worktrees/` | `<repo>/.claude/worktrees/` (gitignored) |
| Removed by | you — `wt rm`, `wt clean`, `ctrl-x` in the `alt+s` picker | Claude Code, on exit or by its periodic sweep |

`trepo.protected` in `.config/git/config` covers `.claude/worktrees`, so the
second kind carries a `protected` flag and `wt clean` never reclaims one: a
sweep is Claude Code's to run, and a locked checkout may still have an agent in
it. It stays listed in `wt` and `wt rm`, which ask before removing it, for the
times a sweep leaves one behind.

## Repositories and herdr workspaces

`repo` opens the navigator below with the repositories under `$REPO_ROOT`
(`~/repos`) queried for — `repo <words>` narrows it further, and clearing the
query brings the other places back. `repo get <owner/repo|url>` clones one and
cd's into the clone.

Clones are placed at `trepo.root/<host>/<path>` (`$REPO_ROOT`, `~/repos`), with
the forge-specific spellings of one repository folded onto a single directory.
Only the two layouts trepo creates are searched — `host/owner/repo` and the
`host/org/project/repo` Azure DevOps needs — so a repository placed at another
depth, or a vendored dependency that ships a `.git`, is not picked up.
`.config/zsh/workflows/repo.zsh` is left with the `cd` that follows.

### One list of places

Open workspaces, worktrees and repositories are all somewhere to go, and the
same checkout used to appear in several lists at once. `wt` (bare), `repo` and
herdr's `alt+s` popup are one picker instead — `_nav_go` in
`.config/zsh/workflows/nav.zsh` — differing only in the initial query and in the
fzf chrome each needs. The candidates are `trepo list` plus the workspaces herdr
has open, and rows are deduplicated by checkout path: an open workspace hides
the checkout it is standing on. A repository's main checkout is a row like any
other — it is where the default branch is checked out — and the checkouts keep
trepo's own order, so a repository and its worktrees stay together and the
cursor lands in the same place on every run. Going to a workspace focuses it, to
a worktree opens it, and to a main checkout creates a workspace with it as the
cwd (`cd` outside herdr). `Tab` switches to the running agents, and `ctrl-x`
removes the worktree under the cursor, or shows why trepo kept it.

Outside a herdr session the workspace and agent rows fall away and everything
degrades to `cd`; the checkouts are unaffected, since trepo reads them from git
rather than from a session.

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
Machine-local overrides go in the gitignored `.config/mise/config.local.toml`
(global) or a repository's own `mise.local.toml`, which may override `[env]`,
`[tools]`, and settings without changing the shared configuration.

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
