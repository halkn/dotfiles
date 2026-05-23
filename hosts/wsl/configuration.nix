{ pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "halkn";

  time.timeZone = "Asia/Tokyo";

  programs.zsh.enable = true;
  users.users.halkn.shell = pkgs.zsh;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
