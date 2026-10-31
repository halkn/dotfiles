# dotfiles

My personal dotfiles for macOS and WSL Ubuntu: zsh, Neovim, Claude Code, and
the CLI tooling around them, set up by [mise](https://mise.jdx.dev/):
`mise.toml` declares the machine and `.config/mise/config.toml` the tools.

## Layout

| Path | Holds | Linked to |
| --- | --- | --- |
| `.config/` | Config for zsh, git, Neovim, mise, herdr and other tools | `~/.config/*` |
| `.zshenv` | Points zsh at `.config/zsh` | `~/.zshenv` |
| `bin/` | Standalone commands (`repo`, `hw`) | `~/.local/bin/*` |
| `claude/` | Claude Code user settings, hooks and global instructions | `~/.claude/*` |
| `.claude/` | Claude Code settings for working on this repository | — |
| `mise.toml`, `mise-tasks/` | What a machine gets besides tools (links, OS packages, repositories, login shell), and the tasks below | — |
| `test/` | Tests for `bin/`, `.config/herdr/`, the Claude Code hooks and the git `pre-push` hook | — |
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

   If a target like `~/.config/git` already exists as a real directory, move it
   aside yourself (e.g. `mv ~/.config/git ~/.config/git.bak`) and run it again. Do not
   reach for `--force-dotfiles`: it overwrites with no backup.

   Until `gh auth login` below, mise calls the GitHub API anonymously, and one
   bootstrap uses about half of the hourly limit. If a rerun hits the limit,
   wait an hour, or run `gh auth login` if `gh` is already installed, then run
   `mise bootstrap --yes --update` again.

1. Set your git identity and log in to GitHub. git authenticates to GitHub
   through `gh`, and `repo` and `hw` call it too.

   ```sh
   git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.name "Your Name"
   git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.email "you@example.com"
   gh auth login
   ```

1. Reopen the terminal. In Ghostty (or Noctty on WSL) zsh starts inside
   [herdr](https://herdr.dev); set `HERDR_AUTO_START=0` in `.zshrc.local` to
   stop that on a machine.

## Machine-local settings

These files are gitignored and hold what differs per machine:

| File | Holds |
| --- | --- |
| `.config/zsh/.zshenv.local` | Environment variables |
| `.config/zsh/.zshrc.local` | Interactive shell settings |
| `.config/mise/config.local.toml` | mise tools and settings for this machine only |
| `mise.local.toml` | Overrides for this repository's mise config, except tools: `mise run update` only upgrades the global config |
| `.config/git/config.local` | `user.name` / `user.email` |
| `.config/nvim/lua/local.lua` | Neovim settings |

## Keeping a machine current

| Task | Use it when |
| --- | --- |
| `mise run sync` | this repository changed and the machine should follow |
| `mise run update` | mise, tools, OS packages, zsh plugins, herdr plugins and Claude Code should move to newer versions |

Only `update` moves versions, and it does not pull, so run `sync` first.

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
- `hw` opens herdr workspaces on clones, branches and pull requests (a
  worktree under `$WT_ROOT` for the latter two) and removes them again.
- `repo` does not change your directory; it prints the path:
  `cd "$(repo list --full-path | fzf)"`.
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
