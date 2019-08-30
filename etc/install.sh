#!/bin/bash

# brew install
echo "brew install start ..."
brew install bat
brew install coreutils
brew install exa
brew install fd
brew install fzf
brew install ghq
brew install git
brew install go
brew install jq
brew install nodebrew
brew install p7zip
brew install ripgrep
brew install tig
brew install tmux
brew install vim
brew install zsh
echo "finished !"

# except XDG_CONFIG_HOME because it is maked by dotdiles deploy
echo "Set up for XDG Base Directory Specification"
mkdir -p ~/.cache
mkdir -p ~/.local/share
mkdir -p ~/.local/share/gem
mkdir -p ~/.local/share/go
mkdir -p ~/.local/share/nodebrew
mkdir -p ~/.local/share/npm
mkdir -p ~/.local/share/tig
mkdir -p ~/.local/share/zsh
echo "finished !"

exit 0
