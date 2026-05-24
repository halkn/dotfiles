{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # claude-code is unfree (Anthropic proprietary); allow just that package.
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
      };
    in
    {
      homeConfigurations."halkn" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home ];
      };
    };
}
