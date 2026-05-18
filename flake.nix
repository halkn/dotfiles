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
          # CLI tools
          ripgrep
          fd
          fzf
          hyperfine
          eza
          delta
          gh
          just
          starship
          neovim
          tree-sitter
          uv
          bun
          rumdl
          markdownlint-cli2

          # Neovim LSP / formatter tools
          lua-language-server
          stylua
          shfmt
          efm-langserver
          shellcheck
          yaml-language-server
        ];
      };
    };
}
