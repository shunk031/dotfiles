DOCKER_IMAGE_NAME=dotfiles
DOCKER_ARCH=x86_64
DOCKER_NUM_CPU=4
DOKCER_RAM_GB=4

#
# Development
#

.PHONY: setup
setup:
	MISE_CONFIG_FILE="$(CURDIR)/home/dot_mise/config.toml" mise install
	MISE_CONFIG_FILE="$(CURDIR)/home/dot_mise/config.toml" mise exec -- prek install

.PHONY: eval-guidance
eval-guidance:
	./scripts/shuhari_guidance_gate.sh eval

# Reconciliation throttles `skills update` to once a day so that `make watch`
# does not fetch on every file save. This forces the update now.
.PHONY: skills-update
skills-update:
	DOTFILES_SKILLS_FORCE_UPDATE=1 bash install/common/skills.sh

#
# Docker
#

.PHONY: docker
docker:
	@if ! docker inspect $(DOCKER_IMAGE_NAME) &>/dev/null; then \
		docker build -t $(DOCKER_IMAGE_NAME) . --build-arg USERNAME="$$(whoami)"; \
	fi
	docker run -it -v "$$(pwd):/home/$$(whoami)/.local/share/chezmoi" --hostname dotfiles-test dotfiles /bin/bash --login

#
# Chezmoi
#

.PHONY: init
init:
	chezmoi init --apply --verbose
	@chezmoi-private init --apply --verbose --ssh shunk031/dotfiles-private || \
		echo "Warning: failed to initialize dotfiles-private. Continuing setup."

.PHONY: update
update:
	chezmoi apply --verbose
	chezmoi-private apply --verbose

.PHONY: watch
watch:
	DOTFILES_DEBUG=1 watchexec -- chezmoi apply --verbose

.PHONY: reset
reset:
	chezmoi state delete-bucket --bucket=scriptState

.PHONY: reset-config
reset-config:
	chezmoi init --data=false

.PHONY: format
format:
	shfmt --indent 4 --space-redirects --diff .
