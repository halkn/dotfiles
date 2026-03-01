# ── History ──────────────────────────────────────────
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=10000
export SAVEHIST=10000
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_expand
setopt share_history

# ── options ──────────────────────────────────────────
setopt ignore_eof
setopt no_flow_control
setopt no_beep
setopt auto_resume
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt list_rows_first
setopt numeric_glob_sort
setopt list_packed
setopt brace_ccl
setopt extended_glob
setopt magic_equal_subst
setopt glob_complete
setopt correct
setopt long_list_jobs
setopt mark_dirs
setopt interactive_comments

# ── keybind ──────────────────────────────────────────
bindkey -e

# ── completion ───────────────────────────────────────
autoload -Uz compinit
# load compinit with XDG cache location for dump file
# skip regeneration if dump file is less than 24 hours old
if [[ -n $ZCACHEDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit -d $ZCACHEDIR/.zcompdump
else
  compinit -C -d $ZCACHEDIR/.zcompdump
fi

# Choose a complementary candidate from the menu.
# select=2: Complement immediately
#           as soon as there are two or more completion candidates
zstyle ':completion:*:default' menu select=2

# Color a completion candidate
# '' : default colors
zstyle ':completion:*:default' list-colors ''

# ambiguous search when no match found
#   m:{a-z}={A-Z} : Ignore UperCace and LowerCase
#   r:|[._-]=*    : Complement it as having a wild card "*" before "." , "_" , "-"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'

# complection format
zstyle ':completion:*' format "--- %d ---"

# grouping for completion list
zstyle ':completion:*' group-name ''

# use cache
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZCACHEDIR/zcompcache

# use detailed completion
zstyle ':completion:*' verbose yes

# how to find the completion list?
# - _complete:      complete
# - _oldlist:       complete from previous result
# - _match:         complete from the suggestin without expand glob
# - _history:       complete from history
# - _ignored:       complete from ignored
# - _approximate:   complete from approximate suggestions
# - _prefix:        complete without caring the characters after carret
zstyle ':completion:*' completer \
  _complete \
  _match \
  _approximate \
  _oldlist \
  _history \
  _ignored \
  _prefix
