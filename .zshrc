

#####################################################################
# history
#####################################################################

## Limit of history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Share history
setopt hist_ignore_dups
setopt share_history

####################################################################
# auto complete
####################################################################
# 補完侯補をメニューから選択する。
# select=2: 補完候補を一覧から選択する。
#           ただし、補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2

# 補完候補に色を付ける。
# "": 空文字列はデフォルト値を使うという意味。
zstyle ':completion:*:default' list-colors ""


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
# 構文のハイライト(https://github.com/zsh-users/zsh-syntax-highlighting)
zplug "zsh-users/zsh-syntax-highlighting"
# history関係
zplug "zsh-users/zsh-history-substring-search"
# タイプ補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"

zplug "chrissicool/zsh-256color" 

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

