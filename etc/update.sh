#!/bin/bash

# brew upgrade
brew upgrade

# go tools
GO111MODULE=off go get -u golang.org/x/lint/golint
GO111MODULE=off go get -u github.com/Code-Hex/battery/cmd/battery
env GO111MODULE=on go get github.com/itchyny/gojq/cmd/gojq
GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
go get github.com/x-motemen/ghq

# npm tools
npm install -g npm
npm install -g markdownlint-cli
npm install -g fixjson

# vim plugin
vim -c PlugUpdate -c qa

exit 0
