set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
zsh_config := ".zshenv .zshrc"
zsh_plugin_dir := "${XDG_DATA_HOME:-$HOME/.local/share}/zsh_plugins"

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
  just install-zsh-plugins

[doc('Update user-space managed tools')]
update:
  just update-nix-tools
  just update-zsh-plugins

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
install-zsh-plugins:
  mkdir -p "{{zsh_plugin_dir}}"
  test -d "{{zsh_plugin_dir}}/zsh-autosuggestions" || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "{{zsh_plugin_dir}}/zsh-autosuggestions"
  test -d "{{zsh_plugin_dir}}/fast-syntax-highlighting" || git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting "{{zsh_plugin_dir}}/fast-syntax-highlighting"

[private]
update-zsh-plugins: install-zsh-plugins
  git -C "{{zsh_plugin_dir}}/zsh-autosuggestions" pull --ff-only
  git -C "{{zsh_plugin_dir}}/fast-syntax-highlighting" pull --ff-only

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
