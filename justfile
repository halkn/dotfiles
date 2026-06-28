default:
    @just --list

# Nix パッケージのインストール（追加・削除後の再適用にも使用）
packages:
    #!/usr/bin/env bash
    set -euo pipefail
    store="$(nix profile list | sed -n 's/^Store paths:[[:space:]]*//p' | head -1)"
    [[ -n "$store" ]] && nix profile remove "$store"
    cd nix && nix profile add .#default

# dotfiles のシンボリンク配置
link:
    #!/usr/bin/env bash
    set -euo pipefail
    dotfiles="{{justfile_directory()}}"
    if [[ -d "$HOME/.config" && ! -L "$HOME/.config" ]]; then
      mv "$HOME/.config" "$HOME/.config.bak.$(date +%s)"
    fi
    ln -snf "$dotfiles/.config" "$HOME/.config"
    ln -snf "$dotfiles/.zshenv" "$HOME/.zshenv"
    mkdir -p "$HOME/.claude" "$HOME/.claude/hooks"
    ln -snf "$dotfiles/claude/settings.json"              "$HOME/.claude/settings.json"
    ln -snf "$dotfiles/claude/CLAUDE.md"                   "$HOME/.claude/CLAUDE.md"
    ln -snf "$dotfiles/claude/statusline-command.sh"       "$HOME/.claude/statusline-command.sh"
    ln -snf "$dotfiles/claude/hooks/block-python.sh"       "$HOME/.claude/hooks/block-python.sh"
    ln -snf "$dotfiles/claude/hooks/block-secret-read.sh"  "$HOME/.claude/hooks/block-secret-read.sh"

# uv インストール
uv:
    ./scripts/install-uv.sh

# フルセットアップ
setup: link packages uv

# ツール更新
update:
    #!/usr/bin/env bash
    set -euo pipefail
    just packages
    command -v claude >/dev/null && claude update || true

# リポジトリ検証
lint: _lint-zsh _lint-md _lint-shfmt _lint-stylua _lint-luals _lint-nvim
    git diff --check

# ファイル整形
fmt:
    rumdl fmt .
    shfmt -w .zshenv .config/zsh/.zshenv .config/zsh/.zshrc
    stylua .config/nvim

# 整形チェック（書き換えなし）
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
    #!/usr/bin/env bash
    set -euo pipefail
    luals_tmp="$(mktemp -d)"
    trap 'rm -rf "$luals_tmp"' EXIT
    VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)"
    export VIMRUNTIME
    lua-language-server --check=.config/nvim --checklevel=Warning --logpath="$luals_tmp/log" --metapath="$luals_tmp/meta"

[private]
_lint-nvim:
    NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
