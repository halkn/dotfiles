#!/bin/bash

# brew upgrade
brew upgrade

# go tools
GO111MODULE=off go get -u golang.org/x/lint/golint

# npm tools
npm install -g npm
npm install -g markdownlint-cli

# vim plugin
vim -c PlugUpdate -c qa

exit 0
