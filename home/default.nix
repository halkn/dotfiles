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
      # CLI utilities
      ripgrep
      fd
      fzf
      eza
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
    "zellij".source = link ".config/zellij";
    "ripgrep".source = link ".config/ripgrep";
    "ptm".source = link ".config/ptm";
    "nix".source = link ".config/nix";
  };

  # zsh plugins from nixpkgs, linked into the dir .zshrc already sources.
  xdg.dataFile = {
    "zsh_plugins/zsh-autosuggestions".source =
      "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    "zsh_plugins/fast-syntax-highlighting".source =
      "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
  };

  home.file = {
    ".zshenv".source = link ".zshenv";
    ".zshrc".source = link ".zshrc";
    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";
    ".claude/statusline-command.sh".source = link "claude/statusline-command.sh";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      hunk-header-decoration-style = "omit";
      navigate = true;
      line-numbers = true;
      side-by-side = true;
      word-diff-regex = "\\S+";
      file-style = "bold yellow ul";
      file-decoration-style = "none";
      blame-code-style = "syntax";
      hyperlinks = true;
    };
  };

  programs.git = {
    enable = true;
    ignores = [
      ".scratch/"
      "**/.claude/settings.local.json"
    ];
    includes = [ { path = "~/.gitconfig.local"; } ];
    settings = {
      alias = {
        st = "status";
        br = "branch";
        ba = "branch -av";
        sw = "switch";
        df = "difftool";
        diff-narrow = "-c delta.side-by-side=false diff";
        pm = ''!f() { base="''${1:-origin/main}"; current=$(git branch --show-current); git for-each-ref --format='%(refname:short)' --merged="$base" refs/heads | while IFS= read -r branch; do [ -n "$branch" ] || continue; [ "$branch" = "$current" ] && continue; [ "$branch" = "main" ] && continue; git branch -d "$branch"; done; }; f'';
      };
      status.showUntrackedFiles = "all";
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        mnemonicPrefix = true;
        renames = true;
      };
      difftool.prompt = false;
      merge.conflictstyle = "zdiff3";
      mergetool.prompt = false;
      color.ui = true;
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      pull.ff = "only";
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      init.defaultBranch = "main";
      safe.bareRepository = "explicit";
    };
  };

  # Authored as TOML / tmux.conf in .config; programs.* generate the live files.
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ../.config/starship/starship.toml);
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../.config/tmux/tmux.conf;
  };
}
