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
          ripgrep
          fd
          fzf
          lsd
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
        ];
      };
    };
}
