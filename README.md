# dotfiles

My personal dotfiles for macOS and WSL Ubuntu: zsh, Neovim, Claude Code, and
the CLI tooling around them, set up by [mise](https://mise.jdx.dev/) from
`mise.toml`.

## Layout

| Path | Holds | Linked to |
| --- | --- | --- |
| `.config/` | Config for zsh, git, Neovim, mise, herdr and other tools | `~/.config` |
| `.zshenv` | Points zsh at `.config/zsh` | `~/.zshenv` |
| `bin/` | Standalone commands (`repo`, `wt`) | `~/.local/bin/*` |
| `claude/` | Claude Code user settings, hooks and global instructions | `~/.claude/*` |
| `.claude/` | Claude Code settings for working on this repository | — |
| `mise.toml`, `mise.lock`, `mise-tasks/` | What a machine gets, and the tasks below | — |
| `test/` | Tests for `bin/` and `.config/herdr/` | — |
| `docs/` | [Design notes](docs/README.md) for changing this repository | — |
| `.github/` | The pull request template | — |

## Setup

1. On WSL Ubuntu, make sure `git` and `curl` are installed. On macOS, accept
   the Xcode Command Line Tools install if the first `git` asks for it.

   ```sh
   sudo apt-get update && sudo apt-get install -y git curl
   ```

1. Clone the dotfiles. All repositories live under `~/repos` as
   `<host>/<path>`.

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/repos/github.com/halkn/dotfiles"
   cd "$HOME/repos/github.com/halkn/dotfiles"
   ```

1. Install mise and bootstrap the machine. It may prompt for sudo and for your
   password when changing the login shell.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   mise trust
   mise bootstrap --yes --update
   ```

   If a target like `~/.config` already exists as a real directory, move it
   aside yourself (e.g. `mv ~/.config ~/.config.bak`) and run it again. Do not
   reach for `--force-dotfiles`: it overwrites with no backup.

1. Set your git identity and log in to GitHub. git authenticates to GitHub
   through `gh`, and `repo` and `wt` call it too.

   ```sh
   git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.name "Your Name"
   git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.email "you@example.com"
   gh auth login
   ```

1. Reopen the terminal. zsh starts inside [herdr](https://herdr.dev); set
   `HERDR_AUTO_START=0` in `.zshrc.local` to stop that on a machine.

## Machine-local settings

These files are gitignored and hold what differs per machine:

| File | Holds |
| --- | --- |
| `.config/zsh/.zshenv.local` | Environment variables |
| `.config/zsh/.zshrc.local` | Interactive shell settings |
| `.config/mise/config.local.toml` | Global mise `[env]`, tools, settings |
| `mise.local.toml` | Overrides for this repository's mise config |
| `.config/git/config.local` | `user.name` / `user.email` |
| `.config/nvim/lua/local.lua` | Neovim settings |

## Keeping a machine current

| Task | Use it when |
| --- | --- |
| `mise run sync` | this repository changed and the machine should follow |
| `mise run update` | mise, tools, OS packages, zsh plugins and Claude Code should move to newer versions |

Only `update` moves versions, and it does not pull, so run `sync` first. Commit
the `mise.lock` diff either task leaves behind.

### Neovim plugins

Plugins are pinned in `.config/nvim/nvim-pack-lock.json`; commit it with every
plugin change.

| To | Run |
| --- | --- |
| update plugins | `:PackUpdate` |
| follow a pulled lockfile | `:restart`, then `:PackUpdate lockfile` |
| remove a plugin | delete its spec, `:restart`, then `:PackClean` |

## Daily use

- `repo` finds, clones and creates repositories under `~/repos`.
- `wt` creates and removes worktrees under `$WT_ROOT`.
- Neither changes your directory; the commands that land somewhere print the
  path: `cd "$(repo list --full-path | fzf)"`, `cd "$(wt new <branch>)"`.
- `repo setup` (which `repo create` also runs) installs a ruleset that
  **blocks direct pushes to the default branch for everyone, admins
  included**. Run `repo setup --dry-run` first.
- herdr opens a workspace per clone or worktree. The keys are in
  `.config/herdr/config.toml`.
- Branches, commits and staging are picked with
  [git-fz](https://github.com/halkn/git-fz).

## Changing this repository

Read the design notes in [docs/](docs/README.md) for the area you are about to
change. [AGENTS.md](AGENTS.md) has the checks to run and the commit and pull
request conventions. It is written for coding agents and applies to people as
well.
