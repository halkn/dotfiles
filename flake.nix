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
          # terminal & shell
          tmux
          starship
          zsh-autosuggestions
          zsh-fast-syntax-highlighting

          # cli
          ripgrep
          fd
          fzf
          eza
          jq
          curl
          unzip
          xclip
          hyperfine

          # vcs
          git
          gh
          ghq
          delta

          # dev tools
          just
          uv
          bun
          (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ])
          snowflake-cli

          # editor
          neovimWrapped

          # lsp / lint / fmt
          lua-language-server
          stylua
          shfmt
          rumdl
          markdownlint-cli2
        ];
      };
    };
}
