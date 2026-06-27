default: lint

lint: lint-zsh lint-md lint-shfmt lint-stylua lint-luals lint-nvim
    git diff --check

fmt:
    rumdl fmt .
    shfmt -w .zshenv .config/zsh/.zshenv .config/zsh/.zshrc
    stylua .config/nvim

fmt-check: lint-md lint-shfmt lint-stylua

setup:
    home-manager switch --flake .

lint-zsh:
    zsh -n .zshenv .config/zsh/.zshenv .config/zsh/.zshrc .config/zsh/lib/*.zsh

lint-md:
    rumdl check .

lint-shfmt:
    shfmt -d .zshenv .config/zsh/.zshenv .config/zsh/.zshrc

lint-stylua:
    stylua --check .config/nvim

lint-luals:
    #!/usr/bin/env bash
    set -euo pipefail
    luals_tmp="$(mktemp -d)"
    trap 'rm -rf "$luals_tmp"' EXIT
    VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q 2>/dev/null)"
    export VIMRUNTIME
    lua-language-server --check=.config/nvim --checklevel=Warning --logpath="$luals_tmp/log" --metapath="$luals_tmp/meta"

lint-nvim:
    NVIM_LOG_FILE=/dev/null nvim --headless -i NONE '+quitall'
