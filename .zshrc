#####################################################################
# OS Type
#####################################################################
case ${OSTYPE} in
    darwin*)
        [[ -f ~/.zsh/mac.zsh ]] && source ~/.zsh/mac.zsh
        ;;
    linux-gnu*)
        [[ -f ~/.zsh/linux.zsh ]] && source ~/.zsh/linux.zsh
        ;;
esac

#####################################################################
# Load Setting
#####################################################################
source ~/.zsh/alias.zsh
source ~/.zsh/setopt.zsh
source ~/.zsh/completion.zsh

#####################################################################
# General Setting
#####################################################################
umask 022

#####################################################################
# plugin manager
#####################################################################
## zplug settings
source ~/.zplug/init.zsh
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

## theme (https://github.com/sindresorhus/pure#zplug)
zplug "mafredri/zsh-async"
zplug "sindresorhus/pure"

## set install plugins
# history関係
zplug "zsh-users/zsh-history-substring-search", defer:3
# 構文のハイライト(https://github.com/zsh-users/zsh-syntax-highlighting)
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# タイプ補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"

# zplug "chrissicool/zsh-256color" 

## Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
# Then, source plugins and add commands to $PATH
zplug load

if (which zprof > /dev/null) ;then
  zprof | less
fi

