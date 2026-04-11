# dotfile

This is my dotfiles.

## Setup

```sh
# Link .config
ln -s ~/.dotfiles/.config ~/.config

# Initialize Codex home and link tracked config only
mkdir -p ~/.codex
ln -snf ~/.dotfiles/codex/config.toml ~/.codex/config.toml
ln -snf ~/.dotfiles/codex/AGENTS.md ~/.codex/AGENTS.md

# Initialize Claude home and link tracked config only
mkdir -p ~/.claude
ln -snf ~/.dotfiles/claude/settings.json ~/.claude/settings.json
ln -snf ~/.dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -snf ~/.dotfiles/claude/statusline-command.sh ~/.claude/statusline-command.sh

# See: https://github.com/astral-sh/uv
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Tool Manager

Tool management has been moved to [halkn/ptm](https://github.com/halkn/ptm).
