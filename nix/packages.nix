{ pkgs }:
with pkgs;
[
  # shell
  zsh
  zsh-autosuggestions
  zsh-fast-syntax-highlighting

  # terminal
  starship
  herdr

  # cli
  ripgrep
  fd
  fzf
  eza
  jq
  yq-go
  hyperfine

  # vcs
  gh
  ghq
  delta
  diffnav

  # dev
  uv
  nodejs

  # editor
  neovim
  tree-sitter

  # LSP / Linter / Formatter
  lua-language-server
  stylua
  shfmt
  efm-langserver
  yamllint
  yamlfmt
  rumdl
  just
]
