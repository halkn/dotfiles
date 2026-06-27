{
  description = "halkn's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      "mac" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        modules = [
          ./home.nix
          {
            home.username = "halkn";
            home.homeDirectory = "/Users/halkn";
          }
        ];
      };
      "wsl" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [
          ./home.nix
          {
            home.username = "halkn";
            home.homeDirectory = "/home/halkn";
          }
        ];
      };
    };
  };
}
