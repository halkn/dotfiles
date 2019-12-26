#!/bin/bash

# brew upgrade
brew upgrade

# go tools
go get golang.org/x/tools/gopls@latest
GO111MODULE=off go get -u golang.org/x/tools/cmd/goimports
GO111MODULE=off go get -u golang.org/x/lint/golint
GO111MODULE=off go get -u github.com/mattn/efm-langserver

# npm tools
npm install -g bash-language-server
npm install -g vim-language-server
npm install -g markdownlint-cli

# vim plugin
vim -c PackUpdate -c qa

exit 0
