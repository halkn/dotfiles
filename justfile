set quiet

nvim_config := ".config/nvim"
zsh_config := ".zshenv .zshrc"
zsh_plugin_dir := "${XDG_DATA_HOME:-$HOME/.local/share}/zsh_plugins"
hm_flake := ".#halkn"

default:
  @just --list

[doc('Run setup')]
setup:
  home-manager switch --flake {{hm_flake}}
  ptm install
  just install-zsh-plugins

[doc('Update user-space managed tools')]
update:
  nix flake update
  home-manager switch --flake {{hm_flake}}
  ptm update
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
