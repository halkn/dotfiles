set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
zsh_config := ".zshenv .zshrc"

default:
  @just --list

[private]
_link:
  ln -snfT "$HOME/.dotfiles/{{config_dir}}" "$HOME/.config"
  ln -snf "$HOME/.dotfiles/.zshenv" "$HOME/.zshenv"
  ln -snf "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
  mkdir -p "$HOME/.claude"
  ln -snf "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
  ln -snf "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  ln -snf "$HOME/.dotfiles/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

[doc('Link dotfiles into home directories')]
link: _link

[doc('Run setup')]
setup: _link
  just install-nix-tools
  just install-claude

[doc('Update user-space managed tools')]
update:
  just update-nix-tools
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
install-nix-tools:
  nix profile list 2>/dev/null | grep -q dotfiles-tools || nix profile install path:.#default

[private]
update-nix-tools:
  nix flake update
  nix profile upgrade --all

[private]
install-claude:
  command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

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
