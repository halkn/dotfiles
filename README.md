# dotfile

This is my dotfiles.

## Setup

```sh
# Bootstrap uv and ptm first.
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install git+https://github.com/halkn/ptm

# Then run the dotfiles setup task.
just setup
```

## Tool Manager

Tool management has been moved to [halkn/ptm](https://github.com/halkn/ptm).
`just` itself is managed by `ptm` after the initial bootstrap.

Useful tasks:

```sh
just          # List tasks
just setup    # Link dotfiles, install apt packages, install ptm tools, install Neovim-managed tools
just update   # Update apt packages, ptm tools, and Neovim-managed tools
just fmt      # Format Neovim Lua files
just lint     # Run repository checks
just status   # Show git status
```

## Neovim

Neovim Lua config uses the Neovim managed `stylua` for formatting and the managed `lua-language-server --check` for diagnostics. The shared LuaLS workspace config lives at `.config/nvim/.luarc.json`.

When changing Neovim Lua settings:

```sh
just fmt
just lint
```

Notes:

- `luals` is not the formatter of record. Keep formatting on `stylua`.
- `conform.nvim` owns format execution for Lua buffers, and LuaLS owns Lua diagnostics.
- Neovim-managed tools live under `${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools`; use absolute paths when running them outside Neovim.
- `nvim-lint` owns Markdown and shell lint execution.
- If `stylua` changes many files, review whether the diff is formatting-only before committing.
