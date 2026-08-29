# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# Keep zsh-owned state and cache under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
zsh_state_dir=$XDG_STATE_HOME/zsh
zsh_cache_dir=$XDG_CACHE_HOME/zsh
mkdir -p "$zsh_state_dir"
mkdir -p "$zsh_cache_dir"
mkdir -p "$zsh_cache_dir/zcompcache"

# ── History ──────────────────────────────────────────
HISTFILE=$zsh_state_dir/history
_legacy_histfile=$zsh_data_dir/history
if [[ ! -e $HISTFILE && -f $_legacy_histfile ]]; then
  mv "$_legacy_histfile" "$HISTFILE" ||
    print 'zsh: failed to migrate history to XDG_STATE_HOME' >&2
fi
unset _legacy_histfile
HISTSIZE=100000
SAVEHIST=10000
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

# ── options ──────────────────────────────────────────
setopt ignore_eof
setopt no_flow_control
setopt no_beep
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt list_rows_first
setopt numeric_glob_sort
setopt list_packed
setopt extended_glob
setopt long_list_jobs
setopt mark_dirs
setopt interactive_comments

# ── keybind ──────────────────────────────────────────
bindkey -e

# ── completion ───────────────────────────────────────
autoload -Uz compinit
zmodload -i zsh/complist

_zcompdump="$zsh_cache_dir/.zcompdump"

# Rebuild the dump roughly daily; otherwise trust the cached dump for startup speed.
if [[ ! -s "$_zcompdump" || -n "$_zcompdump"(#qN.mh+23) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi

unset _zcompdump

zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:default' list-colors ''

# Try exact completion first, then progressively looser matching.
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*'

zstyle ':completion:*' format '--- %d ---'
zstyle ':completion:*' group-name ''

zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$zsh_cache_dir/zcompcache"

zstyle ':completion:*' verbose yes

setopt complete_in_word

# Keep completers small; heavier fuzzy/correction completers are intentionally omitted.
zstyle ':completion:*' completer \
  _complete \
  _match \
  _prefix

# ── aliases ──────────────────────────────────────────
alias ll='ls -lhF'
alias la='ls -lhAF'
alias du='du -h'
alias df='df -h'
alias ..='cd ..'
alias zs='exec zsh'
alias :q='exit'
# A fixed destination, so it skips the picker `wk open` would show. The body is
# evaluated when the alias runs, which is why `_ck_repo_root` (lib/checkout.zsh,
# sourced further down) is already there by then.
alias dot='cd -- "$(_ck_repo_root)/github.com/halkn/dotfiles"'

# ── plugins (git clone) ───────────────────────────────
zsh_plugins_dir=$zsh_data_dir/plugins
[[ -f "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] &&
  source "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# ── uv ───────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  _uv_comp="$zsh_cache_dir/uv_completion.zsh"
  if [[ ! -s "$_uv_comp" || "$(command -v uv)" -nt "$_uv_comp" ]]; then
    uv generate-shell-completion zsh >|"$_uv_comp"
  fi
  source "$_uv_comp"
  unset _uv_comp
fi

# ── fzf ──────────────────────────────────────────────
# The shell-wide bits: the widgets, the look, and the per-command completion
# sources. Workflows built on fzf live under workflows/. The integration script
# calls compdef, so it has to come after compinit above.
if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
  export FZF_DEFAULT_OPTS="
    --height 60%
    --layout=reverse
    --border
    --info=inline
    --preview-window=right:60%:wrap
    --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
    --bind ctrl-/:toggle-preview
  "

  # Provides the widgets: Ctrl-R (history), Ctrl-T (paste paths), Alt-C (cd).
  source <(fzf --zsh)

  # `<command> **<TAB>` is where selecting plus one command lives, so those need
  # no function of their own: the source and the preview follow the command
  # being completed.

  # Preview for the completions whose source is the default path walker.
  _fzf_comprun() {
    local cmd=$1
    shift
    case $cmd in
      cd | rmdir)
        fzf --preview 'ls -la {}' "$@"
        ;;
      # bat is not installed here, hence cat.
      cat | less | head | tail | cp | mv | rm | touch | chmod | ln | tar | zip | unzip | nvim | v)
        fzf --preview 'cat {}' "$@"
        ;;
      *)
        fzf "$@"
        ;;
    esac
  }

  # `$1` is the whole command line; `prefix` is the word being completed and is
  # set by the caller in fzf's completion.zsh, hence the `-` default here.
  _fzf_complete_git() {
    local -a tokens
    local token sub
    tokens=(${(z)1})
    # The subcommand is the first word that is not git itself or an option, so
    # that `git -C <dir> switch` still completes as `switch`.
    for token in ${tokens[2,-1]}; do
      [[ $token == -* ]] && continue
      sub=$token
      break
    done

    case $sub in
      switch | checkout | branch | br)
        # `%(refname:short)` renders the remote HEAD symref as a bare `origin`.
        # The second field drops the `origin/` prefix: `git switch <name>` tracks
        # the remote branch, while `git switch origin/<name>` detaches HEAD.
        _fzf_complete --delimiter '\t' --with-nth 1 --accept-nth 2 \
          --preview 'git log --oneline --graph --color=always {1} -- | head -200' \
          -- "$@" < <(
            git branch --all --sort=-committerdate --format='%(refname:short)' 2>/dev/null \
              | grep -vx origin \
              | while IFS= read -r ref; do printf '%s\t%s\n' "$ref" "${ref#origin/}"; done
          )
        ;;
      add | restore)
        _fzf_complete --multi \
          --preview "source ${_GIT_LIB}; _git_stage_preview {}" \
          -- "$@" < <(_git_stage_rows)
        ;;
      log | show)
        _fzf_complete --ansi --no-sort --accept-nth 1 \
          --preview 'git show --color=always {1}' \
          -- "$@" < <(git log --color=always --format='%C(auto)%h %s %C(dim)%cr' 2>/dev/null)
        ;;
      *)
        _fzf_path_completion "${prefix-}" "$1"
        ;;
    esac
  }
fi

# ── eza ──────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --no-user --time-style=iso --group-directories-first'
  alias la='eza -la --icons --git --no-user --time-style=iso --group-directories-first'
  alias ltr='eza -l --icons --git --no-user --time-style=iso --sort=modified --group-directories-first'
  alias lst='eza -l --icons --git --no-user --time-style=iso --sort=modified --reverse --group-directories-first'
  alias tree='eza --tree --icons -I ".git" --group-directories-first'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  export MANPAGER='nvim +Man!'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

# ── reviewr ──────────────────────────────────────────
if command -v herdr-reviewr >/dev/null 2>&1; then
  alias gd='herdr-reviewr'
fi

# ── workflows ────────────────────────────────────────
# Each file defines its functions unconditionally and checks its dependencies
# inside them, so no conditions belong here and the load order does not matter.
# lib/ is not globbed: a workflow sources the parts it needs itself, which is
# what lets ~/.config/herdr/*.sh get a whole workflow from one file.
for _zsh_part in "$ZDOTDIR"/workflows/*.zsh(N); do
  source "$_zsh_part"
done
unset _zsh_part

# ── starship ─────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

# ── machine-local overrides (not tracked in git) ─────
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# ── herdr ────────────────────────────────────────────
# `exec` replaces the shell, so this stays the last thing .zshrc does - which is
# also what lets .zshrc.local above turn the auto-start off.
# HERDR_ENV is set inside herdr-managed shells and stops the recursion.
HERDR_AUTO_START=${HERDR_AUTO_START:-1}

if command -v herdr >/dev/null 2>&1 &&
  [[ -o interactive ]] &&
  [[ -z $HERDR_ENV ]] &&
  [[ -t 0 ]] &&
  [[ -t 1 ]] &&
  [[ $HERDR_AUTO_START == 1 ]]; then
  exec herdr
fi
