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
| `mise.toml`, `mise-tasks/` | What a machine gets, and the tasks below | — |
| `test/` | Tests for `bin/` and `.config/herdr/` | — |
| `docs/` | [Design notes](docs/README.md) for changing this repository | — |
| `.github/` | The pull request template | — |

## Setup

### Platform prerequisites

On a fresh WSL Ubuntu, only `git` and `curl` are needed before cloning this
repo and installing mise. They are usually preinstalled — check with `git
--version && curl --version`. If either is missing, install it first:

```sh
sudo apt-get update && sudo apt-get install -y git curl
```

macOS needs nothing here.

### Bootstrap

1. Clone the dotfiles. All repositories live under `~/repos` as
   `<host>/<path>`, so place it at that path.

   ```sh
   git clone https://github.com/halkn/dotfiles.git "$HOME/repos/github.com/halkn/dotfiles"
   cd "$HOME/repos/github.com/halkn/dotfiles"
   ```

1. Install mise and bootstrap the machine.

   ```sh
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   mise trust
   mise bootstrap --yes --update
   ```

   It may prompt for sudo when installing OS packages and for your password
   when changing the login shell.

1. Reopen the terminal to start zsh with the linked config.

If a target like `~/.config` already exists as a real directory, move it aside
yourself (e.g. `mv ~/.config ~/.config.bak`) and run the bootstrap again. Do not
reach for `mise bootstrap --force-dotfiles`: it overwrites with no backup.

### Git identity

The git config includes an untracked `config.local` next to it. Set your name
and email there on each machine:

```sh
git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.name "Your Name"
git config -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/config.local" user.email "you@example.com"
```

### Machine-local settings

These files are gitignored and hold what differs per machine:

| File | Holds |
| --- | --- |
| `.config/zsh/.zshenv.local` | Environment variables |
| `.config/zsh/.zshrc.local` | Interactive shell settings |
| `.config/mise/config.local.toml` | Global mise `[env]`, tools, settings |
| `mise.local.toml` | Overrides for this repository's mise config |
| `.config/git/config.local` | `user.name` / `user.email` |

## Keeping a machine current

The bootstrap above runs once per machine. After that, two tasks keep it
current:

| Task | Use it when | Moves versions |
| --- | --- | --- |
| `mise run sync` | this repository changed and the machine should follow | no — it only installs what a new declaration added |
| `mise run update` | tools, OS packages, zsh plugins and Claude Code should move to newer versions | yes — it is the only task that does |

`update` does not pull this repository, so run `sync` first. Commit the
`mise.lock` diff either task leaves behind.

### Neovim plugins

Neovim plugins are managed by the built-in `vim.pack`, wrapped in commands by
`.config/nvim/lua/vimrc/pack.lua`. Commit `.config/nvim/nvim-pack-lock.json`
with every plugin change.

- Update with `:PackUpdate`.
- On another machine, pull the lockfile, `:restart`, then run
  `:PackUpdate lockfile`.
- To remove a plugin, delete its spec, `:restart`, then run `:PackClean`.

## Daily use

- **Clones**: `repo` finds, clones and creates repositories under `~/repos`.
  **Worktrees**: `wt` creates and removes them under `$WT_ROOT`.
  See `repo --help` and `wt --help`. Both only print paths, so moving there is
  up to you: `cd "$(repo list --full-path | fzf)"`, `cd "$(wt new <branch>)"`.
- `repo setup` (which `repo create` also runs) installs a ruleset that
  **blocks direct pushes to the default branch for everyone, admins
  included**. Run `repo setup --dry-run` first.
- **[herdr](https://herdr.dev)** opens a workspace per clone or worktree. The keys are in
  `.config/herdr/config.toml`, and each script they run describes itself in
  its header.
- **Branches, commits and staging** are picked with
  [git-fz](https://github.com/halkn/git-fz).

## Changing this repository

Read the design notes in [docs/](docs/README.md) for the area you are about to
change. [AGENTS.md](AGENTS.md) has the checks to run and the commit and pull
request conventions. It is written for
coding agents and applies to people as well.
