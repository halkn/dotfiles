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

## Neovim

Neovim Lua config uses the Neovim managed `stylua` for formatting and the managed `lua-language-server --check` for diagnostics. The shared LuaLS workspace config lives at `.config/nvim/.luarc.json`.

When changing Neovim Lua settings:

```sh
# Install/update Neovim-managed tools when needed
nvim --headless -i NONE '+NvimToolsInstall' '+quitall'

# Format and lint all Neovim Lua files
NVIM_TOOLS="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools/bin"
"$NVIM_TOOLS/stylua" .config/nvim
"$NVIM_TOOLS/stylua" --check .config/nvim
"$NVIM_TOOLS/lua-language-server" --check=.config/nvim --checklevel=Warning --logpath=/tmp/luals-check-log --metapath=/tmp/luals-check-meta

# Smoke test startup
nvim --headless -i NONE '+quitall'
```

Notes:

- `luals` is not the formatter of record. Keep formatting on `stylua`.
- `conform.nvim` owns format execution for Lua buffers, and LuaLS owns Lua diagnostics.
- Neovim-managed tools live under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools`; use absolute paths when running them outside Neovim.
- `nvim-lint` owns Markdown and shell lint execution.
- If `stylua` changes many files, review whether the diff is formatting-only before committing.
