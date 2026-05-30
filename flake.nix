{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages.x86_64-linux.default = pkgs.buildEnv {
        name = "dotfiles-tools";
        paths = with pkgs; [
          # terminal
          tmux
          starship

          # zsh plugins
          zsh-autosuggestions
          zsh-fast-syntax-highlighting

          # CLI utilities
          ripgrep
          fd
          fzf
          eza
          delta
          jq
          curl
          unzip
          xclip
          hyperfine

          # dev
          neovim
          tree-sitter
          git
          gh
          (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ])
          snowflake-cli
          just
          uv
          bun

          # LSP / Linter / Formatter
          lua-language-server
          stylua
          shfmt
          efm-langserver
          shellcheck
          yaml-language-server
          rumdl
          markdownlint-cli2
        ];
      };
    };
}
