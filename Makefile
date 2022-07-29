DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

SHELL := /usr/bin/bash

init:
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/install.sh

deploy:
	@DOTPATH=$(DOTPATH) source $(DOTPATH)/etc/deploy.sh && deploy_dotfiles_cmd "gui"
