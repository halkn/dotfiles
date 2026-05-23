{
  config,
  pkgs,
  lib,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.username = lib.mkDefault "halkn";
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.isDarwin then "/Users/halkn" else "/home/halkn"
  );
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages =
    with pkgs;
    [
      # terminal
      tmux
      starship

      # CLI utilities
      ripgrep
      fd
      fzf
      eza
      delta
      jq
      curl
      unzip
      hyperfine

      # dev
      neovim
      tree-sitter
      gh
      just
      uv
      bun

      # LSP / Linter / Formatter
      lua-language-server
      stylua
      shfmt
      efm-langserver
      shellcheck
      yaml-language-server
      rumdl
      markdownlint-cli2
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [ xclip ];

  # Hand-written configs stay in the repo and are linked out-of-store so they
  # remain editable in place without a home-manager rebuild.
  xdg.enable = true;
  xdg.configFile = {
    "nvim".source = link ".config/nvim";
    "tmux".source = link ".config/tmux";
    "zellij".source = link ".config/zellij";
    "starship".source = link ".config/starship";
    "git".source = link ".config/git";
    "ripgrep".source = link ".config/ripgrep";
    "ptm".source = link ".config/ptm";
    "nix".source = link ".config/nix";
  };

  home.file = {
    ".zshenv".source = link ".zshenv";
    ".zshrc".source = link ".zshrc";
    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";
    ".claude/statusline-command.sh".source = link "claude/statusline-command.sh";
  };
}
