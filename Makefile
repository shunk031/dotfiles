IMAGE_NAME=dotfiles

#
# Docker
#
.PHONY: docker
docker:
	@if [[ $$(limactl list colima --format "{{.Status}}") == "Stopped" ]]; then \
		colima start --arch x86_64 --cpu 4 --memory 4 --mount "$${HOME}/ghq/:w" --mount "$${HOME}/.local/share/chezmoi/:w"; \
	fi
	@if ! docker inspect $(IMAGE_NAME) &>/dev/null; then \
		docker build -t $(IMAGE_NAME) . --build-arg USERNAME="$$(whoami)"; \
	fi
	docker run -it -v "$$(pwd):/home/$$(whoami)/.local/share/chezmoi" dotfiles /bin/bash --login

#
# Chezmoi
#

.PHONY: apply
apply:
	chezmoi apply --verbose

.PHONY: watch
watch:
	watchexec -- chezmoi apply --verbose
