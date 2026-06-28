dotfiles := justfile_directory()

[default]
[private]
list:
    @just --list

# ── Setup ────────────────────────────────────────────

[doc("フルセットアップ（link → Nix packages → uv tools → Claude Code）")]
[group("setup")]
setup: link
    nix profile add .#default
    curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
    uv tool install ryl
    curl -fsSL https://claude.ai/install.sh | bash

[doc("dotfiles の symlink を配置")]
[group("setup")]
link:
    [ -d "$HOME/.config" ] && [ ! -L "$HOME/.config" ] && \
      mv "$HOME/.config" "$HOME/.config.bak.$(date +%s)" || true
    ln -snf "{{ dotfiles }}/.config" "$HOME/.config"
    ln -snf "{{ dotfiles }}/.zshenv" "$HOME/.zshenv"
    find "{{ dotfiles }}/claude" -type f | while read -r src; do \
      rel="${src#{{ dotfiles }}/claude/}"; \
      mkdir -p "$HOME/.claude/$(dirname "$rel")"; \
      ln -snf "$src" "$HOME/.claude/$rel"; \
    done

# ── Maintenance ──────────────────────────────────────

[doc("Nix パッケージと Claude Code を更新")]
[group("maintenance")]
update:
    nix flake update
    nix profile upgrade dotfiles
    command -v claude && claude update || true

# ── Quality ──────────────────────────────────────────

[doc("リポジトリ検証")]
[group("quality")]
lint: _lint-zsh _lint-md _lint-shfmt _lint-stylua _lint-luals _lint-nvim
    git diff --check

[doc("ファイル整形")]
[group("quality")]
fmt:
    rumdl fmt .
    shfmt -w .zshenv .config/zsh/.zshenv .config/zsh/.zshrc
    stylua .config/nvim

[doc("整形チェック（書き換えなし）")]
[group("quality")]
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
