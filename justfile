set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
zsh_config := ".zshenv .config/zsh/.zshenv .config/zsh/.zshrc"

default:
  @just --list

[private]
_link:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ -d "$HOME/.config" && ! -L "$HOME/.config" ]]; then
    rm -rf "$HOME/.config"
  fi
  ln -snfT "$HOME/.dotfiles/{{config_dir}}" "$HOME/.config"
  ln -snf "$HOME/.dotfiles/.zshenv" "$HOME/.zshenv"
  mkdir -p "$HOME/.claude"
  ln -snf "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
  ln -snf "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  ln -snf "$HOME/.dotfiles/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  mkdir -p "$HOME/.claude/hooks"
  ln -snf "$HOME/.dotfiles/claude/hooks/block-python.sh" "$HOME/.claude/hooks/block-python.sh"

[doc('Link dotfiles into home directories')]
link: _link

[doc('Run setup')]
setup: _link
  just install-mise
  just install-mise-tools
  just install-zsh-plugins
  just install-claude
  just install-tpm

[doc('Update user-space managed tools')]
update:
  just update-mise-tools
  just update-zsh-plugins
  just update-claude

[doc('Run repository checks that pass on the current tree')]
lint: diff-check check-tools lint-zsh lint-md lint-shfmt lint-lua lint-nvim

[doc('Check formatting without writing files')]
fmt-check: lint-md lint-shfmt lint-stylua

[doc('Format files with configured formatters')]
fmt:
  rumdl fmt .
  shfmt -w {{zsh_config}}
  stylua {{nvim_config}}

[private]
check-tools:
  command -v zsh >/dev/null
  command -v rumdl >/dev/null
  command -v nvim >/dev/null
  command -v shfmt >/dev/null
  command -v stylua >/dev/null
  command -v lua-language-server >/dev/null

[private]
install-mise:
  command -v mise >/dev/null || curl https://mise.run | sh

[private]
install-mise-tools:
  mise install

[private]
update-mise-tools:
  mise upgrade --all

[private]
install-zsh-plugins:
  #!/usr/bin/env bash
  set -euo pipefail
  plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
  mkdir -p "$plugins_dir"
  test -d "$plugins_dir/zsh-autosuggestions" \
    || git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
  test -d "$plugins_dir/fast-syntax-highlighting" \
    || git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugins_dir/fast-syntax-highlighting"

[private]
update-zsh-plugins:
  #!/usr/bin/env bash
  set -euo pipefail
  plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
  for dir in "$plugins_dir"/*/; do
    [[ -d "${dir}.git" ]] && git -C "$dir" pull --ff-only
  done

[private]
install-claude:
  command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

[private]
install-tpm:
  test -d "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm" || git clone https://github.com/tmux-plugins/tpm "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm"

[private]
update-claude:
  command -v claude >/dev/null && claude update || true

[private]
diff-check:
  git diff --check

[private]
lint-zsh:
  zsh -n {{zsh_config}}

[private]
lint-md:
  rumdl check .

[private]
lint-shfmt:
  shfmt -d {{zsh_config}}

[private]
lint-stylua:
  stylua --check {{nvim_config}}

[private]
lint-luals:
  luals_tmp="$(mktemp -d)" && trap 'rm -rf "$luals_tmp"' EXIT && VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)" lua-language-server --check={{nvim_config}} --checklevel=Warning --logpath="$luals_tmp/log" --metapath="$luals_tmp/meta"

[private]
lint-lua: lint-stylua lint-luals

[private]
lint-nvim:
  NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
