# load command completion function
autoload -Uz compinit
# load compinit
compinit

# 補完侯補をメニューから選択する。
# select=2: 補完候補を一覧から選択する。
#           ただし、補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2

# 補完候補にLS_COLORSと同じ色を付ける。 
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

