{ pkgs, lib, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "halkn";

  time.timeZone = "Asia/Tokyo";

  # claude-code is unfree (Anthropic proprietary); allow just that package.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  programs.zsh.enable = true;
  # home-manager runs compinit (programs.zsh.enableCompletion); avoid a second one.
  programs.zsh.enableGlobalCompInit = false;
  users.users.halkn.shell = pkgs.zsh;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
