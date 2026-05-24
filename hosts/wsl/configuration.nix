{ pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "halkn";

  time.timeZone = "Asia/Tokyo";

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
