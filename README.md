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

# See: https://github.com/astral-sh/uv
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Tool Manager

Tool management has been moved to [halkn/ptm](https://github.com/halkn/ptm).
