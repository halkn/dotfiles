set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
nvim_tools := "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools/bin"
zsh_config := ".config/zsh/.zshenv .config/zsh/.zshrc"
zsh_plugin_dir := "${XDG_DATA_HOME:-$HOME/.local/share}/zsh_plugins"

default:
  @just --list

[private]
_link:
  ln -snfT "$HOME/.dotfiles/{{config_dir}}" "$HOME/.config"
  mkdir -p "$HOME/.codex"
  ln -snf "$HOME/.dotfiles/codex/config.toml" "$HOME/.codex/config.toml"
  ln -snf "$HOME/.dotfiles/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  mkdir -p "$HOME/.claude"
  ln -snf "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
  ln -snf "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  ln -snf "$HOME/.dotfiles/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

[doc('Link dotfiles into home directories')]
link: _link

[doc('Run setup')]
setup: _link
  ptm install
  just install-zsh-plugins
  just install-tools

[doc('Update user-space managed tools')]
update:
  ptm update
  just update-zsh-plugins
  just update-tools

[doc('Run repository checks that pass on the current tree')]
lint: diff-check check-tools lint-zsh lint-md lint-shfmt lint-lua lint-nvim

[doc('Check formatting without writing files')]
fmt-check: lint-md lint-shfmt lint-stylua

[doc('Format files with configured formatters')]
fmt:
  rumdl fmt .
  {{nvim_tools}}/shfmt -w {{zsh_config}}
  {{nvim_tools}}/stylua {{nvim_config}}

[private]
check-tools:
  command -v zsh >/dev/null
  command -v rumdl >/dev/null
  command -v nvim >/dev/null
  test -x "{{nvim_tools}}/shfmt"
  test -x "{{nvim_tools}}/stylua"
  test -x "{{nvim_tools}}/lua-language-server"

[private]
install-tools:
  nvim --headless -i NONE '+NvimToolsInstall' '+quitall'

[private]
update-tools:
  nvim --headless -i NONE '+NvimToolsUpdate' '+quitall'

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
  {{nvim_tools}}/shfmt -d {{zsh_config}}

[private]
lint-stylua:
  {{nvim_tools}}/stylua --check {{nvim_config}}

[private]
lint-luals:
  luals_tmp="$(mktemp -d)" && trap 'rm -rf "$luals_tmp"' EXIT && "{{nvim_tools}}/lua-language-server" --check={{nvim_config}} --checklevel=Warning --logpath="$luals_tmp/log" --metapath="$luals_tmp/meta"

[private]
lint-lua: lint-stylua lint-luals

[private]
lint-nvim:
  NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
