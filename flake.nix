{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-nightly-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        neovim-nightly = neovim-nightly-overlay.packages.${system}.default;

        nvimTools = with pkgs; [
          efm-langserver
          tree-sitter
        ];

        neovim-wrapped = pkgs.symlinkJoin {
          name = "neovim-nightly";
          paths = [ neovim-nightly ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/nvim \
              --prefix PATH : ${pkgs.lib.makeBinPath nvimTools}
          '';
        };
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
            curl
            just
            ripgrep
            fd
            fzf
            eza
            jq
            yq-go
            hyperfine

            # vcs
            git
            gh
            ghq
            delta

            # dev
            nodejs

            # editor
            neovim-wrapped

            # Linter / Formatter
            lua-language-server
            stylua
            shfmt
            rumdl
          ];
        };
      }
    );
}
