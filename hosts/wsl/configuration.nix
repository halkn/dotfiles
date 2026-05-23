{ pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "halkn";

  programs.zsh.enable = true;
  users.users.halkn.shell = pkgs.zsh;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
