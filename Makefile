ROOT_PATH     := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES    := $(wildcard .??*)
EXCLUSIONS    := .git .gitignore
DOTFILES      := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

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
	@echo ''
	@echo '==> End to deploy dotfiles to home directory.'

init:
	@echo '==> Start to Initialize'
	@echo ''
	@DOTPATH=$(ROOT_PATH) bash $(ROOT_PATH)/etc/install.sh
	@echo ''
	@echo '==> End to Initialize'

