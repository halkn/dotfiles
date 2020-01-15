#!/bin/bash

# brew upgrade
brew upgrade

# go tools
GO111MODULE=off go get -u golang.org/x/lint/golint
GO111MODULE=off go get -u github.com/mattn/efm-langserver

# npm tools
npm install -g markdownlint-cli

# vim plugin
vim -c PackUpdate -c qa

exit 0
