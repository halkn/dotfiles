{ config, pkgs, lib, ... }:

{
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    zsh
    herdr
    jq
    yq
    hyperfine
    ghq
    diffnav
    uv
    nodejs
    stylua
    shfmt
    rumdl
    lua-language-server
    yamllint
    yamlfmt
    just
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
    extraPackages = with pkgs; [
      efm-langserver
      tree-sitter
    ];
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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$username$hostname$directory$git_branch$git_state$git_status$python$cmd_duration$line_break$character";
      directory.style = "blue";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };
      git_branch = {
        symbol = " ";
        style = "bright-black";
      };
      git_commit.tag_symbol = "  ";
      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
      };
      git_state = {
        format = "([\\[$all_status$ahead_behind\\]]($style))";
        style = "bright-black";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
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

  programs.fd = {
    enable = true;
    ignores = [
      ".git/"
      "node_modules/"
    ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

  programs.git = {
    enable = true;
    ignores = [ ".scratch/" "**/.claude/settings.local.json" "mise.local.toml" ];
    includes = [{ path = "config.local"; }];
    settings = {
      alias = {
        st = "status";
        br = "branch";
        ba = "branch -av";
        sw = "switch";
        sm = "!git switch main && git pull && git pm";
        df = "difftool";
        diff-narrow = "-c delta.side-by-side=false diff";
        pm = "!f() { base=\"\${1:-origin/main}\"; current=$(git branch --show-current); git for-each-ref --format='%(refname:short)' --merged=\"$base\" refs/heads | while IFS= read -r branch; do [ -n \"$branch\" ] || continue; [ \"$branch\" = \"$current\" ] && continue; [ \"$branch\" = \"main\" ] && continue; git branch -d \"$branch\"; done; }; f";
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
      ghq.root = "~/repos";
      "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
    };
  };

  xdg.configFile = {
    "nvim".source = ./.config/nvim;
    "zsh".source = ./.config/zsh;
    "herdr".source = ./.config/herdr;
    "nix/nix.conf" = { source = ./.config/nix/nix.conf; force = true; };
    "yamllint".source = ./.config/yamllint;
    "yamlfmt".source = ./.config/yamlfmt;
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    "snowflake".source = ./.config/snowflake;
  };

  home.file = {
    ".zshenv".source = ./.zshenv;
    ".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
    ".claude/settings.json".source = ./claude/settings.json;
    ".claude/statusline-command.sh".source = ./claude/statusline-command.sh;
    ".claude/hooks/block-python.sh".source = ./claude/hooks/block-python.sh;
    ".claude/hooks/block-secret-read.sh".source = ./claude/hooks/block-secret-read.sh;
  };
}
