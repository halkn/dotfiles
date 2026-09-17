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

`mise run setup` (= `mise bootstrap --yes --update`) converges every
machine-state declaration in `mise.toml` and is idempotent. It may prompt for
sudo when installing OS packages and for your password during `chsh`.

If a target like `~/.config` already exists as a real directory (not a
symlink), mise won't overwrite it. Back it up yourself first (e.g.
`mv ~/.config ~/.config.bak`) — `mise bootstrap --force-dotfiles`
**overwrites the conflicting files in place with no backup**. Preview with
`mise bootstrap --dry-run` or `mise bootstrap status` first.

When the bootstrap finishes, reopen the terminal (or start a new login
shell) to enter zsh with the linked config.

`setup` is for the first run on a machine. Afterwards:

| Task | Use it when |
| --- | --- |
| `mise run sync` | this repo changed and the machine should follow the new declarations |
| `mise run update` | a tool or external component should move to a newer version |

Both are run by hand. `update` never pulls this repo, so `sync` first if you
want the current declarations. Commit the lockfile diff either way.

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
`.github/pull_request_template.md`. `AGENTS.md` holds the constraints that
apply to any change here.

## What is here

| Path | Holds |
| --- | --- |
| `.zshenv`, `.config/zsh/` | The shell. A `$HOME` stub sets `ZDOTDIR`; everything else is XDG |
| `.config/nvim/` | Neovim. Plugins are managed by the built-in `vim.pack` |
| `claude/`, `.claude/` | Claude Code: the linked config, and this repo's own project config |
| `.config/mise/` | The tools every directory gets; `mise.toml` holds the ones only this repo uses |
| `mise-tasks/` | The `mise run` tasks that are longer than one command |

Two commands are the entry points to the daily workflows. Run them with
`--help` for the current usage:

- `wk` — get a repository, open it, branch off it in a worktree, move between
  what is open, remove what is done. Inside [herdr](https://herdr.dev) each
  choice becomes a workspace; outside it degrades to `cd`.
- `ghsetup` — apply this repo's standard settings to a GitHub repository
  (branch ruleset, secret scanning, merge and Dependabot settings). The
  ruleset grants **no bypass actor, including repository admins**, so applying
  it takes away your own push to the default branch. Look at `--dry-run`
  first.

Interactive selection goes through [fzf](https://github.com/junegunn/fzf):
`<command> **<TAB>` completions and the `Ctrl-R` / `Ctrl-T` / `Alt-C` widgets
are set up in the `fzf` section of `.zshrc`.

## Machine-local settings

These files are gitignored and hold what differs per machine:

| File | Holds |
| --- | --- |
| `.config/zsh/.zshenv.local` | Environment variables |
| `.config/zsh/.zshrc.local` | Interactive shell settings |
| `.config/mise/config.local.toml` | Global mise `[env]`, tools, settings |
| `mise.local.toml` | Overrides for this repository's mise config |
| `.config/git/config.local` | `user.name` / `user.email` |
