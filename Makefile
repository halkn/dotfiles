ROOT_PATH     := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES    := $(wildcard .??*)
EXCLUSIONS    := .git 
DOTFILES      := $(filter-out $(EXCLUSIONS), $(CANDIDATES))
NVIM_CONF_DIR := ~/.config/nvim

list: 
	@echo '==> Show Target dotfiles.'
	@echo ''
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)
	@echo ''
	@echo '==> Show Exclusions dotfiles.'
	@$(foreach val, $(EXCLUSIONS), /bin/ls -dF $(val);)

deploy: 
	@echo '==> Start to deploy dotfiles to home directory.'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@mkdir -p $(NVIM_CONF_DIR)
	@echo ''
	@echo '==> End to deploy dotfiles to home directory.'

init:
	@echo '==> Start to Initialize'
	@echo '$(NVIM_CONF_DIR)'
	@echo '==> End to Initialize'

