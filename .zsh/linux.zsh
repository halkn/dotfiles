# Linux Setting
# Color support
if [ "$TERM" = "xterm" ]
then
    export TERM="xterm-256color"
fi

# ls color
alias ls='ls --color=auto'

# open for WSL ( like macOS)
alias open="cmd.exe /c start"
