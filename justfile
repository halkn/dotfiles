set shell := ["bash", "-euo", "pipefail", "-c"]

dotfiles := justfile_directory()

[default]
[private]
list:
    @just --list

# ── Setup ────────────────────────────────────────────

[group("setup")]
[doc("フルセットアップ（link → Nix packages → uv）")]
setup: link
    nix profile add .#default
    curl -LsSf https://astral.sh/uv/install.sh | sh

[group("setup")]
[doc("dotfiles の symlink を配置")]
link:
    if [[ -d "$HOME/.config" && ! -L "$HOME/.config" ]]; then \
      mv "$HOME/.config" "$HOME/.config.bak.$(date +%s)"; \
    fi
    ln -snf "{{dotfiles}}/.config" "$HOME/.config"
    ln -snf "{{dotfiles}}/.zshenv" "$HOME/.zshenv"
    mkdir -p "$HOME/.claude" "$HOME/.claude/hooks"
    ln -snf "{{dotfiles}}/claude/settings.json"              "$HOME/.claude/settings.json"
    ln -snf "{{dotfiles}}/claude/CLAUDE.md"                   "$HOME/.claude/CLAUDE.md"
    ln -snf "{{dotfiles}}/claude/statusline-command.sh"       "$HOME/.claude/statusline-command.sh"
    ln -snf "{{dotfiles}}/claude/hooks/block-python.sh"       "$HOME/.claude/hooks/block-python.sh"
    ln -snf "{{dotfiles}}/claude/hooks/block-secret-read.sh"  "$HOME/.claude/hooks/block-secret-read.sh"

# ── Maintenance ──────────────────────────────────────

[group("maintenance")]
[doc("Nix パッケージと Claude Code を更新")]
update:
    nix flake update
    nix profile upgrade dotfiles
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
    rm -rf /tmp/luals-check
    VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)" \
      lua-language-server --check=.config/nvim --checklevel=Warning --logpath=/tmp/luals-check/log --metapath=/tmp/luals-check/meta
    rm -rf /tmp/luals-check

[private]
_lint-nvim:
    NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
