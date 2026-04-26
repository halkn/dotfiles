set quiet

config_dir := ".config"
nvim_config := ".config/nvim"
nvim_tools := "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/managed-tools/bin"
luals_log := "/tmp/luals-check-log"
luals_meta := "/tmp/luals-check-meta"

default:
  @just --list

[doc('Show repository status')]
status:
  git status --short

[doc('Check for whitespace and patch formatting issues')]
diff-check:
  git diff --check

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

[doc('Run first-time setup')]
setup: _link
  sudo apt update -y
  sudo apt upgrade -y
  ptm install
  nvim --headless -i NONE '+NvimToolsInstall' '+quitall'

[doc('Run repository checks that pass on the current tree')]
lint: diff-check
  zsh -n .config/zsh/.zshenv .config/zsh/.zshrc .config/zsh/conf.d/*.zsh
  {{nvim_tools}}/stylua --check {{nvim_config}}
  {{nvim_tools}}/lua-language-server --check={{nvim_config}} --checklevel=Warning --logpath={{luals_log}} --metapath={{luals_meta}}
  nvim --headless -i NONE '+quitall'

[doc('Format files with configured formatters')]
fmt:
  {{nvim_tools}}/stylua {{nvim_config}}

[doc('Update OS packages and ptm-managed tools')]
update:
  sudo apt update -y
  sudo apt upgrade -y
  ptm update
  nvim --headless -i NONE '+NvimToolsUpdate' '+quitall'
