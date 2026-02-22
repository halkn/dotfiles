{
  description = "Dev tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"  # Apple Silicon
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.buildEnv {
            name = "dev-tools";
            paths = with pkgs; [
              ripgrep fd fzf eza delta ghq gh starship
              markdownlint-cli2
              lua-language-server
              bash-language-server shfmt shellcheck
            ];
          };
        }
      );
    };
}
