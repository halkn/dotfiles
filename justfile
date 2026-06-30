dotfiles := justfile_directory()

[default]
[private]
list:
    @just --list

# ── Setup ────────────────────────────────────────────

[group("setup")]
[doc("フルセットアップ（link → mise tools → zsh plugins → Claude Code）")]
setup: link
    mise install
    just _plugins
    curl -fsSL https://claude.ai/install.sh | bash

[group("setup")]
[doc("dotfiles の symlink を配置")]
link:
    [ -d "$HOME/.config" ] && [ ! -L "$HOME/.config" ] && \
      mv "$HOME/.config" "$HOME/.config.bak.$(date +%s)" || true
    ln -snf "{{dotfiles}}/.config" "$HOME/.config"
    ln -snf "{{dotfiles}}/.zshenv" "$HOME/.zshenv"
    mkdir -p "$HOME/.claude" "$HOME/.claude/hooks"
    ln -snf "{{dotfiles}}/claude/settings.json"              "$HOME/.claude/settings.json"
    ln -snf "{{dotfiles}}/claude/CLAUDE.md"                   "$HOME/.claude/CLAUDE.md"
    ln -snf "{{dotfiles}}/claude/statusline-command.sh"       "$HOME/.claude/statusline-command.sh"
    ln -snf "{{dotfiles}}/claude/hooks/block-python.sh"       "$HOME/.claude/hooks/block-python.sh"
    ln -snf "{{dotfiles}}/claude/hooks/block-secret-read.sh"  "$HOME/.claude/hooks/block-secret-read.sh"

[private]
_plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    mkdir -p "$plugins_dir"
    clone() { [ -d "$1/.git" ] || git clone --depth=1 "$2" "$1"; }
    clone "$plugins_dir/zsh-autosuggestions" https://github.com/zsh-users/zsh-autosuggestions
    clone "$plugins_dir/fast-syntax-highlighting" https://github.com/zdharma-continuum/fast-syntax-highlighting

[private]
_plugins-update:
    #!/usr/bin/env bash
    set -euo pipefail
    plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    for dir in "$plugins_dir"/*/; do
        [ -d "${dir}.git" ] || continue
        git -C "$dir" pull --ff-only
    done

# ── Maintenance ──────────────────────────────────────

[group("maintenance")]
[doc("mise ツール・zsh プラグイン・Claude Code を更新")]
update:
    mise upgrade
    just _plugins-update
    command -v claude && claude update || true

# ── Quality ──────────────────────────────────────────

[group("quality")]
[doc("リポジトリ検証")]
lint: _lint-zsh _lint-md _lint-shfmt _lint-stylua _lint-luals _lint-nvim
    git diff --check

[group("quality")]
[doc("ファイル整形")]
fmt:
    rumdl fmt .
    shfmt -w .zshenv .config/zsh/.zshenv .config/zsh/.zshrc
    stylua .config/nvim

[group("quality")]
[doc("整形チェック（書き換えなし）")]
fmt-check: _lint-md _lint-shfmt _lint-stylua

[private]
_lint-zsh:
    zsh -n .zshenv .config/zsh/.zshenv .config/zsh/.zshrc .config/zsh/lib/*.zsh

[private]
_lint-md:
    rumdl check .

[private]
_lint-shfmt:
    shfmt -d .zshenv .config/zsh/.zshenv .config/zsh/.zshrc

[private]
_lint-stylua:
    stylua --check .config/nvim

[private]
_lint-luals:
    rm -rf "${TMPDIR:-/tmp}"/luals-check
    VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)" \
      lua-language-server --check=.config/nvim --checklevel=Warning \
      --logpath="${TMPDIR:-/tmp}"/luals-check/log --metapath="${TMPDIR:-/tmp}"/luals-check/meta
    rm -rf "${TMPDIR:-/tmp}"/luals-check

[private]
_lint-nvim:
    NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
