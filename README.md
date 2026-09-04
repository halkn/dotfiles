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
| `workflows/*.zsh` | The commands you type: `wk` (repositories, worktrees, workspaces), `gst` (staging) and `ghsetup` (GitHub repository settings). One operation is one subcommand |
| `lib/*.zsh` | One file per kind of information a command works on: `checkout` (where a checkout lives here), `forge` (what GitHub knows and what a repository there should be set to), `session` (herdr), `ui` (picker chrome, dependency checks, preview) |

The two layers answer different questions: a workflow owns *the operation you
asked for*, a lib owns *one kind of information*, which is what stops the same
listing or the same preview from being written once per command. `session.zsh`
is the only file that runs `herdr`, so the line between what only a shell can do
(`cd`) and what an external command does is a file boundary — and the day this
grows into a CLI of its own, that is the line it gets cut along.

A lib never sources another lib or a workflow; a workflow sources the libs it
needs by absolute path, which is what lets `.config/herdr/*.sh` pull in a whole
workflow from one file. Neither layer carries a dependency guard at file level:
they define their functions unconditionally and check inside them, because a
function that never got defined would fail silently in those herdr popups.

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

## Working on repositories: `wk`

`wk` (`.config/zsh/workflows/wk.zsh`) is the single entry point for getting a
repository, opening it, branching off it in a worktree, moving between what is
open, and removing what is done. Inside [herdr](https://herdr.dev) each choice
becomes a workspace; outside it degrades to `cd`.

```sh
wk                        # go to a workspace or a worktree
wk open [<query>...]      # open a repository or a place as a workspace
wk get [<owner/repo|url>] # clone one in and open it
wk new <branch> [base]    # create the worktree for a branch and open it
wk pr [<number>]          # create the worktree for a pull request and open it
wk rm                     # pick worktrees of this repository to remove
```

The bare form and `open` span every repository; `new`, `pr` and `rm` act on the
one you are standing in.

### Getting and opening

`wk get <owner/repo|url>` clones into `$REPO_ROOT` (`~/repos`) and opens the
clone, and is an open with no clone when it is already there. The spec may drop
the scheme: `owner/repo` and `github.com/owner/repo` are both cloned over https,
and a first segment that looks like a host (`dev.azure.com/...`) is used as one.
With no argument it lists your GitHub repositories through `gh` and clones the
one picked; the ones already under the root are marked rather than hidden.

Clones land at `$REPO_ROOT/<host>/<owner>/<repo>`, and only that layout plus the
`<host>/<org>/<project>/<repo>` Azure DevOps needs is searched — a repository
placed at another depth, or a vendored dependency that ships a `.git`, is not
picked up. `dot` — an alias in `.zshrc`, since it is a fixed destination rather
than a picker — jumps straight to this checkout.

`wk open` is where to *start* working: the repositories under `$REPO_ROOT`, plus
the directories that are not repositories but are worked in anyway — `$HOME` and
the temp dir by default, held in `$WS_PLACES` (`:`-separated, like PATH). A path
this machine does not have is dropped from the listing, so a WSL `/mnt/c` is
added with `WS_PLACES=$WS_PLACES:/mnt/c` in `.zshenv.local` and the OS stays out
of the workflow. Going to something that is already open is bare `wk` below.

### Worktrees

Parallel work (reviewing a branch while developing another) uses one worktree
per branch. Worktrees are placed at `$WT_ROOT/<owner>/<repo>/<branch>`, outside
the `$REPO_ROOT` tree `wk open` browses. `$WT_ROOT` (`.zshenv`) and herdr's own
`[worktrees] directory` hold the same path (`~/.local/share/worktrees`), so both
put worktrees in one tree and the two values move together. That layout is what the listing is: a glob over the
root, so no git process is spawned per row. A `/` in a branch name is folded to
`-`, so two branches differing only in that separator would share a directory.

`wk new` picks a branch up where it already is — locally first, then on
`origin` — and only creates one when there is nothing to pick up, so a branch
that exists only on the remote is tracked rather than silently forked. A base
given as the second argument always means a new branch. A new checkout is
pre-trusted for mise, since it holds code from a repository you already work in.
Creating a worktree stays here rather than going through `herdr worktree create`
for that reason: the branch resolution is the point, and herdr is handed the
finished checkout to open.

`wk pr` without a number picks from the open pull requests. The checkout is left
to `gh pr checkout` inside a detached worktree, since that is what gets a fork's
head right — the branch is named after the pull request's head branch, so two
pull requests proposing the same branch name from different forks collide the
same way the `/` folding does.

`wk rm` leaves the decision to git: a worktree with local changes is refused,
and the refusal is shown before it asks whether to force it. Unpushed commits do
not stop a removal, and the branch itself is left behind — delete it with
`git branch -d` (the same rule as the `git pm` alias) when you are done with it.

Three worktrees are not offered at all, because `git worktree remove` takes each
of them without complaint: the repository's main checkout, the worktree you are
standing in (removing it would leave the shell in a directory that is gone) and
anything under `.claude/worktrees`.

Claude Code creates worktrees of its own, so the two kinds are kept apart:

| | `wk` / herdr | Claude Code |
| --- | --- | --- |
| For | branch and multi-session work a human returns to | isolating a session or a subagent while it runs |
| Created by | `wk new`, herdr `alt+g` | `--worktree`, `EnterWorktree`, `isolation: worktree` |
| Placed in | `~/.local/share/worktrees/` | `<repo>/.claude/worktrees/` (gitignored) |
| Removed by | you — `wk rm` | Claude Code, on exit or by its periodic sweep |

Claude Code's are inside the repository and so outside `$WT_ROOT`: they do not
appear in the `wk` listing, and `wk rm` excludes them by path, so sweeping them
stays Claude Code's job — one of them may still have an agent running in it.

### Moving between what is open, and herdr

Bare `wk` and herdr's `alt+s` popup are the same picker — `_wk_go_pick`, called
with no arguments from both. `alt+n` is `_wk_open_pick` and `alt+g` is `wk new`
with the branch read in the popup, replacing herdr's own `new_worktree` so that
every worktree is placed and branched the same way. The scripts in
`.config/herdr/` exist only because a herdr popup runs a command rather than a
shell, so the workflow has to be sourced first; each one sources `wk.zsh` and
calls one function. The look is the picker's own (`_UI_FZF_CHROME`: full screen,
preview under the list) rather than `FZF_DEFAULT_OPTS`, which sizes the
completions that pop up under the cursor.

The listing puts the open herdr workspaces first, then every worktree under
`$WT_ROOT`; the two are not deduplicated, so a worktree that is open appears
both as its workspace and as itself. Going to a workspace focuses it, going to a
worktree opens it as a workspace, or focuses the one it already has.

Outside a herdr session the workspace rows fall away and everything degrades to
`cd`; the worktrees are unaffected, since they are read off the filesystem
rather than from a session.

## Repository settings on GitHub: `ghsetup`

```zsh
ghsetup                     # apply to the repository you stand in
ghsetup <owner>/<repo>      # apply to another one
ghsetup --dry-run [<repo>]  # read the current settings without writing
```

Run it once after `gh repo create`. A personal account cannot make these apply
to repositories that do not exist yet — rulesets are scoped to a repository or
to an organisation, and the organisation-wide target needs a paid plan — so this
command stands in for that. It is idempotent: an existing ruleset is updated
rather than duplicated.

What it sets:

- a ruleset on the default branch that requires a pull request (no approval; a
  lone owner cannot approve their own) and blocks force pushes and deletion
- secret scanning with push protection, which rejects a secret at push time
  rather than reporting it after publication
- auto-merge, branch update, delete-on-merge; wiki and projects off
- Dependabot alerts and security updates

The ruleset grants **no bypass actor**, including repository admins. An agent
runs under the same ssh key and gh token as the person who started it, so an
admin bypass would be a bypass for both; an exception means turning the ruleset
off in the web UI on purpose. Since applying it takes away your own push to the
default branch, look at `--dry-run` first.

This is the server-side half. `.config/git/hooks/pre-push` refuses force pushes
to and deletions of `main`/`master` in every repository via `core.hooksPath`,
which covers forges without rulesets and fails before anything leaves the
machine; the ruleset covers what a hook cannot, since a hook can be skipped.

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
so commit that too. Both lockfiles cover the platforms named in the `lockfile_platforms` setting
(`macos-arm64` and `linux-x64`), and `mise run update` runs `mise lock` for
both config roots because an upgrade only records the platform it ran on. Versions only move to releases older than
`minimum_release_age` (3 days), so a just-published release is not selectable
yet; tools published from this account opt out with a per-tool
`minimum_release_age = "0s"`.

mise shell activation uses PATH mode rather than shims. Keep shell aliases and
functions in zsh; use mise's `[env]` only for project-specific environments.
Machine-local overrides go in the gitignored `.config/mise/config.local.toml`
(global) or a repository's own `mise.local.toml`, which may override `[env]`,
`[tools]`, and settings without changing the shared configuration.

Task automation uses [mise tasks](https://mise.jdx.dev/tasks/), run with
`mise run` (`mise tasks` lists them). A task whose body is a single command is
declared in `mise.toml`; anything longer is a file task under `mise-tasks/`,
where it keeps a real shebang and is covered by `shuck`.

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
