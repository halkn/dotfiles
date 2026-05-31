{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # Tools only accessible from within neovim
      nvimTools = with pkgs; [
        tree-sitter
        efm-langserver
        shellcheck
        yaml-language-server
      ];

      neovimWrapped = pkgs.symlinkJoin {
        name = "neovim-wrapped";
        paths = [ pkgs.neovim ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/nvim \
            --prefix PATH : ${pkgs.lib.makeBinPath nvimTools}
        '';
      };
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
          neovimWrapped
          git
          gh
          ghq
          (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ])
          snowflake-cli
          just
          uv
          bun

          # Linter / Formatter (also used by just lint / just fmt)
          lua-language-server
          stylua
          shfmt
          rumdl
          markdownlint-cli2
        ];
      };
    };
}
