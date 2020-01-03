DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*) bin
EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml .secret.zsh.example .pypirc.example .github
DOTFILES   := $(sort $(filter-out $(EXCLUSIONS), $(CANDIDATES)))

.DEFAULT_GOAL := help

all:

list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

deploy: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@echo ''

init: ## Setup environment settings
	@echo '==> Start to init dotfiles'
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/install/main.sh
	@echo ''

test: ## Test dotfiles and init scripts
	@echo "test is inactive temporarily"

update: ## Fetch changes for this repo
	git pull origin master
	git submodule init
	git submodule update
	git submodule foreach git pull origin master

install: ## Run make update, deploy, init
	update
	deploy
	init
	local
	@exec $$SHELL

clean: ## Remove the dot files and this repo
	@echo '==> Remove dot files in your home directory.'
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(val);)

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

local:
	@echo '==> Start to create local config files.'
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/install/local.sh
	@echo ''
