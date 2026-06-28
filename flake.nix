{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.buildEnv {
          name = "dotfiles";
          paths = with pkgs; [
            # shell
            zsh
            zsh-autosuggestions
            zsh-fast-syntax-highlighting

            # terminal
            starship
            herdr

            # cli
            git
            curl
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
          ];
        };
      }
    );
}
