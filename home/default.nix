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

  # No NixOS to enable these system-wide, so persist them in the user nix.conf
  # (~/.config/nix/nix.conf). After the first switch, `home-manager switch
  # --flake` and `just switch` work without extra flags. home-manager needs an
  # explicit nix.package to generate/validate the conf on non-NixOS.
  nix.package = pkgs.nix;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  home.packages =
    with pkgs;
    [
      # CLI utilities
      jq
      curl
      unzip
      hyperfine

      # dev
      neovim
      tree-sitter
      gh
      ghq
      just
      uv
      bun
      claude-code
      (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ])

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
    "ptm".source = link ".config/ptm";
  };

  home.file = {
    ".claude/settings.json".source = link "claude/settings.json";
    ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";
    ".claude/statusline-command.sh".source = link "claude/statusline-command.sh";
  };

  # Environment moved out of .zshenv; paths resolved at eval time so they do
  # not depend on shell-time ordering of XDG_* exports.
  home.sessionVariables = {
    LANG = "C.UTF-8";
    EDITOR = "nvim";
    PAGER = "less";
    MANPAGER = "nvim +Man!";
    LESS = "-g -i -M -R -S -W -z-4 -x4";
    LESSHISTFILE = "-";

    XDG_CONFIG_HOME = config.xdg.configHome;
    XDG_CACHE_HOME = config.xdg.cacheHome;
    XDG_DATA_HOME = config.xdg.dataHome;
    XDG_STATE_HOME = config.xdg.stateHome;
    XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";

    BUN_INSTALL = "${config.home.homeDirectory}/.bun";

    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    UV_PYTHON_PREFERENCE = "only-managed";
    UV_PROJECT_ENVIRONMENT = ".venv";
    UV_COMPILE_BYTECODE = "true";

    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship/cache";

    AZURE_CONFIG_DIR = "${config.xdg.configHome}/azure";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.bun/bin"
  ];

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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Nerd-font glyphs are built from codepoints via fromJSON so the source
    # stays pure ASCII; raw private-use bytes get mangled by some editors.
    settings =
      let
        branch = builtins.fromJSON ''"\uf418"''; # nf git branch glyph U+F418
        tag = builtins.fromJSON ''"\uf412"''; # nf git commit tag glyph U+F412
        promptR = builtins.fromJSON ''"\u276f"''; # prompt arrow right U+276F
        promptL = builtins.fromJSON ''"\u276e"''; # prompt arrow left U+276E
      in
      {
        format = "$username$hostname$directory$git_branch$git_state$git_status$python$cmd_duration$line_break$character";
        directory.style = "blue";
        character = {
          success_symbol = "[${promptR}](purple)";
          error_symbol = "[${promptR}](red)";
          vimcmd_symbol = "[${promptL}](green)";
        };
        git_branch = {
          symbol = "${branch} ";
          style = "bright-black";
        };
        git_commit.tag_symbol = " ${tag} ";
        git_status = {
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
          style = "cyan";
        };
        git_state = {
          format = ''([\[$all_status$ahead_behind\]]($style))'';
          style = "bright-black";
        };
        cmd_duration = {
          format = "[$duration]($style) ";
          style = "yellow";
        };
      };
  };

  # tmux.conf is imperative; keep it hand-written and read it in verbatim.
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../.config/tmux/tmux.conf;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 60%"
      "--layout=reverse"
      "--border"
      "--info=inline"
      "--preview-window=right:60%:wrap"
      "--bind ctrl-u:preview-page-up,ctrl-d:preview-page-down"
      "--bind ctrl-/:toggle-preview"
    ];
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
      "--glob=!node_modules"
    ];
  };

  # fd is smart-case by default; mirror ripgrep's hidden + ignore set.
  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".git/"
      "node_modules"
    ];
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = false;
  };

  # Hybrid zsh: the interactive body stays hand-written (initContent), while
  # env, history, aliases, plugins, integrations and prompt come from home-manager.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autosuggestion.enable = true;
    history = {
      path = "${config.xdg.dataHome}/zsh/history";
      size = 100000;
      save = 10000;
      expireDuplicatesFirst = true;
      saveNoDups = true;
      findNoDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --git --no-user --time-style=iso --group-directories-first";
      la = "eza -la --icons --git --no-user --time-style=iso --group-directories-first";
      ltr = "eza -l --icons --git --no-user --time-style=iso --sort=modified --group-directories-first";
      lst = "eza -l --icons --git --no-user --time-style=iso --sort=modified --reverse --group-directories-first";
      tree = "eza --tree --icons -I .git --group-directories-first";
      v = "nvim";
      vim = "nvim";
      vimdiff = "nvim -d";
      du = "du -h";
      df = "df -h";
      ".." = "cd ..";
      dot = "cd $HOME/.dotfiles";
      zs = "exec zsh";
      ":q" = "exit";
    };
    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
    ];
    initContent = lib.mkMerge [
      (builtins.readFile ../.config/zsh/.zshrc)
      # Source untracked per-machine overrides last so they can override the
      # managed config. Mirrors the ~/.gitconfig.local include used for git.
      (lib.mkAfter ''
        [[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
      '')
    ];
  };
}
