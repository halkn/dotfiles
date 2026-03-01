# ── aliases ──────────────────────────────────────────
# ls
alias ls='ls --color=auto'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias ltr='ls -lhFtr'

# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# human readable for du and df
alias du='du -h'
alias df='df -h'

# cd
alias ..='cd ..'

# etc
alias path='echo $PATH | tr ":" "\n"'
alias zs='source $ZDOTDIR/.zshrc'
alias zb='for i in $(seq 1 10); do time zsh -i -c exit; done'
alias dot='cd $HOME/.dotfiles && $EDITOR'
alias :q='exit'
