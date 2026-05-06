set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
nvim_tools := "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools/bin"
zsh_config := ".config/zsh/.zshenv .config/zsh/.zshrc .config/zsh/conf.d/*.zsh"

default:
  @just --list

[doc('Show repository status')]
status:
  git status --short

[doc('Check for whitespace and patch formatting issues')]
diff-check:
  git diff --check

[doc('Check required commands and managed tools')]
check-tools:
  command -v zsh >/dev/null
  command -v rumdl >/dev/null
  command -v nvim >/dev/null
  test -x "{{nvim_tools}}/shfmt"
  test -x "{{nvim_tools}}/stylua"
  test -x "{{nvim_tools}}/lua-language-server"

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

[doc('Install Neovim managed tools')]
install-tools:
  nvim --headless -i NONE '+NvimToolsInstall' '+quitall'

[doc('Update Neovim managed tools')]
update-tools:
  nvim --headless -i NONE '+NvimToolsUpdate' '+quitall'

[doc('Run user-space setup without apt')]
setup-user: _link
  ptm install
  just install-tools

[doc('Run first-time setup')]
setup: _link
  sudo apt update -y
  sudo apt upgrade -y
  ptm install
  just install-tools

[doc('Run repository checks that pass on the current tree')]
lint: diff-check check-tools lint-zsh lint-md lint-shfmt lint-lua lint-nvim

[doc('Check zsh syntax')]
lint-zsh:
  zsh -n {{zsh_config}}

[doc('Check Markdown')]
lint-md:
  rumdl check .

[doc('Check shell formatting')]
lint-shfmt:
  {{nvim_tools}}/shfmt -d {{zsh_config}}

[doc('Check Neovim Lua formatting')]
lint-stylua:
  {{nvim_tools}}/stylua --check {{nvim_config}}

[doc('Check Neovim Lua diagnostics')]
lint-luals:
  luals_tmp="$(mktemp -d)" && trap 'rm -rf "$luals_tmp"' EXIT && "{{nvim_tools}}/lua-language-server" --check={{nvim_config}} --checklevel=Warning --logpath="$luals_tmp/log" --metapath="$luals_tmp/meta"

[doc('Check Neovim Lua')]
lint-lua: lint-stylua lint-luals

[doc('Check Neovim startup')]
lint-nvim:
  NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'

[doc('Check formatting without writing files')]
fmt-check: lint-md lint-shfmt lint-stylua

[doc('Format files with configured formatters')]
fmt:
  rumdl fmt .
  {{nvim_tools}}/shfmt -w {{zsh_config}}
  {{nvim_tools}}/stylua {{nvim_config}}

[doc('Update user-space managed tools without apt')]
update-user:
  ptm update
  just update-tools

[doc('Update OS packages and ptm-managed tools')]
update:
  sudo apt update -y
  sudo apt upgrade -y
  ptm update
  just update-tools
