#!/bin/bash

# brew install
echo "brew install start ..."
brew install zsh
brew install git
brew install coreutils
brew install tig
brew install tmux
brew install vim
brew install fzf
brew install ripgrep
brew install fd
brew install p7zip
brew install shellcheck
echo "finished !"

# except XDG_CONFIG_HOME because it is maked by dotdiles deploy
echo "Set up for XDG Base Directory Specification"
mkdir -p ~/.cache
mkdir -p ~/.local/share
mkdir -p ~/.local/share/tig
mkdir -p ~/.local/share/zsh
echo "finished !"

exit 0
