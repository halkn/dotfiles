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

1. Install mise and bootstrap the machine. `mise trust` whitelists this repo's
   `mise.toml` so its declarations are allowed to run.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   mise trust
   mise bootstrap --yes --update
   ```

This converges every machine-state declaration in `mise.toml` and is
idempotent. It may prompt for sudo when installing OS packages and for your
password during `chsh`. `--update` is for the package index a fresh machine has
never fetched; it also fast-forwards `[bootstrap.repos]`, harmless here because
they are being cloned.

If a target like `~/.config` already exists as a real directory (not a
symlink), mise won't overwrite it. Back it up yourself first (e.g.
`mv ~/.config ~/.config.bak`) — `mise bootstrap --force-dotfiles`
**overwrites the conflicting files in place with no backup**. Preview with
`mise bootstrap --dry-run` or `mise bootstrap status` first.

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config. This command is the first run on a
machine and is not repeated; afterwards use `mise run sync` and
`mise run update`, see [Tool Manager](#tool-manager).

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

## Changing this repo

```sh
mise run fmt   # shuck, stylua, rumdl
mise run lint  # the format checks, the per-language checks and the tests
```

`mise tasks` lists the rest. Pull requests follow
`.github/pull_request_template.md`.

## Shell layout

zsh keeps its config under `.config/zsh` (XDG); the only file in `$HOME` is a
small `.zshenv` stub that sets `ZDOTDIR` and hands off to it.

| Location | Holds |
| --- | --- |
| `.zshenv` | The shared environment and PATH |
| `.zshrc` | The portable interactive core, plus tool setup guarded by `command -v` so a machine without those tools still gets a working shell |
| `workflows/*.zsh` | The commands that need the shell itself: `wk` |
| `lib/*.zsh` | One file per kind of information those commands work on |
| `test/*.zsh` | Run by `mise run test:zsh` |

`bin/*` sits outside that tree: commands that need neither a picker nor `cd`
live there as executables on PATH, so anything can call them. `repo` is one.

Which layer a change belongs in, and the constraints each layer carries, are in
`.claude/skills/zsh-workflows/SKILL.md`. Why an individual function is written
the way it is belongs in that file's own header comment.

Interactive selection goes through [fzf](https://github.com/junegunn/fzf):
`<command> **<TAB>` completions and the `Ctrl-R` / `Ctrl-T` / `Alt-C` widgets
are set up in the `fzf` section of `.zshrc`.

Selecting branches, commits and files to stage is not part of that: it lives in
[git-fz](https://github.com/halkn/git-fz) as `git fz switch`, `git fz log` and
`git fz stage`, installed as a tool like any other.

## Clones: `repo`

`repo` (`bin/repo`) is everything about the local clones and their GitHub-side
settings. It reads and writes nothing but stdout and an exit status: it opens no
picker, changes no directory, and knows nothing about a terminal multiplexer.
Selecting and arriving belong to whoever calls it, which is what lets it be
lifted out of this repository later.

```sh
repo root                         # print $REPO_ROOT
repo list [--full-path] [<query>] # the clones under it, one per line
repo dest <spec>                  # where <spec> would land
repo get [-u] <spec>              # clone it; with -u, update an existing one
repo create [--public] <name>     # create it on GitHub, clone it, configure it
repo setup [--dry-run] [<nwo>]    # apply the GitHub-side settings
```

A `<spec>` is `<owner>/<repo>`, a clone URL, or a bare name resolved against
your own account. `get` and `create` print where the clone is, so `cd "$(repo
get halkn/git-fz)"` is how you arrive; combined with a picker it is
`cd "$(repo list --full-path | fzf)"`.

Clones land at `$REPO_ROOT/<host>/<owner>/<repo>` (`~/repos`), plus the
`<host>/<org>/<project>/<repo>` depth Azure DevOps needs. A repository at
another depth is not listed.

`-u` updates on the way past: a failed `git pull --ff-only` is reported but
still prints the path, because a branch with no upstream or a dirty tree is no
reason to withhold a directory that is there.

## Worktrees: `wk`

`wk` (`.config/zsh/workflows/wk.zsh`) is the entry point for worktrees: cutting
one for a branch or a pull request, moving between what is open, and removing
what is done. Inside [herdr](https://herdr.dev) each choice becomes a workspace;
outside it degrades to `cd`.

```sh
wk                        # go to a workspace or a worktree
wk new <branch> [base]    # create the worktree for a branch and open it
wk pr [<number>]          # create the worktree for a pull request and open it
wk rm                     # pick worktrees of this repository to remove
```

The bare form spans every repository; `new`, `pr` and `rm` act on the one you
are standing in.

Worktrees land at `$WT_ROOT/<owner>/<repo>/<branch>`
(`~/.local/share/worktrees`). herdr's own `[worktrees] directory` holds the same
path, so the two values must be changed together.

Claude Code creates worktrees of its own, so the two kinds are kept apart:

| | `wk` / herdr | Claude Code |
| --- | --- | --- |
| For | branch and multi-session work a human returns to | isolating a session or a subagent while it runs |
| Created by | `wk new`, herdr `alt+g` | `--worktree`, `EnterWorktree`, `isolation: worktree` |
| Placed in | `~/.local/share/worktrees/` | `<repo>/.claude/worktrees/` (gitignored) |
| Removed by | you — `wk rm` | Claude Code, on exit or by its periodic sweep |

Claude Code's are inside the repository and so outside `$WT_ROOT`, which keeps
them out of the `wk` listing; `wk rm` excludes them by path as well, because one
of them may still have an agent running in it.

`wk rm` leaves the decision to git, which refuses a worktree with local changes
but not one with unpushed commits, and leaves the branch behind — delete it with
`git branch -d` when you are done with it. Three worktrees are never offered,
because git removes each without complaint: the main checkout, the one you are
standing in, and anything under `.claude/worktrees`.

When removing several worktrees, `wk rm` attempts each selected target and
returns a failure if any removal fails or its force confirmation is declined.
Cancelling the picker is a successful no-op; picker errors remain failures.

herdr's `alt+s` and `alt+g` are bare `wk` and `wk new`; `alt+n` picks from
`repo list` and opens a workspace on the result. All three are
`.config/herdr/*.sh`, and the herdr-specific half lives only there.

### `repo setup`

`repo create` runs it for you; run it by hand on a repository that predates it.
It is idempotent: an existing ruleset is updated rather than duplicated. What it
sets:

- a ruleset on the default branch that requires a pull request and blocks force
  pushes and deletion
- secret scanning with push protection
- auto-merge, branch update, delete-on-merge; wiki and projects off
- Dependabot alerts and security updates

The ruleset grants **no bypass actor**, including repository admins, so applying
it takes away your own push to the default branch. Look at `--dry-run` first;
an exception means turning the ruleset off in the web UI on purpose.

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

The two roots differ in what they promise. The global config declares *which*
tools a machine gets, not which build: there is no lockfile beside it, so each
machine resolves `latest` when it installs, and two machines set up months apart
land on different versions on purpose. What guards that is
`minimum_release_age` (3 days) — a release published less than three days ago is
not selectable, which is the window for a compromised one to be yanked upstream.
Tools published from this account opt out of the wait per tool.

`mise.lock` pins the tools declared in `mise.toml` — the Lua toolchain
(`stylua`, `emmylua_ls`, `emmylua_check`), whose diagnostics change between
releases and would otherwise turn `mise run lint` red on one machine and green
on another. It does not cover the rest of what `lint` runs: `rumdl`, `shuck`
and `nvim` are global tools and move freely, so `fmt-check` can disagree across
machines until they are updated together. Only `mise run update` moves the
versions in the lockfile. Commit the diff — after `update` it is the update
itself, after `sync` it means a newly declared tool had no locked version yet.

mise shell activation uses PATH mode rather than shims. Keep shell aliases and
functions in zsh; use mise's `[env]` only for project-specific environments.
A [mise task](https://mise.jdx.dev/tasks/) whose body is a single command is
declared in `mise.toml`; anything longer is a file task under `mise-tasks/`,
where it keeps a real shebang and is covered by `shuck`.

The two machine-state tasks are separated by the state transition they make,
not by the commands they happen to run. The first run on a machine is not among
them — it is `mise bootstrap --yes --update`, typed once from
[Setup](#bootstrap) above.

| Task | Use it when | Moves versions | Touches machine-global state |
| --- | --- | --- | --- |
| `sync` | this repo changed (here or on another machine) and the machine should follow | no — it installs what a new declaration added and leaves what is already there | yes — OS packages, login shell, symlinks, by converging on the new declarations |
| `update` | a tool or external component should move to a newer version | yes — it is the only task that does | yes, but only versions of what is already declared |

`update` never pulls this repo: run `sync` first if you want the current
declarations, then `update`, then commit the `mise.lock` diff. Its steps are
independent, so a failing step is reported and the rest still run.

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

## Machine-local settings

These files are gitignored and hold what differs per machine:

| File | Holds |
| --- | --- |
| `.config/zsh/.zshenv.local` | Environment variables |
| `.config/zsh/.zshrc.local` | Interactive shell settings |
| `.config/mise/config.local.toml` | Global mise `[env]`, tools, settings |
| `mise.local.toml` | Overrides for this repository's mise config |
| `.config/git/config.local` | `user.name` / `user.email` |
