.PHONY: colima-start
colima-start:
	colima start --arch x86_64 --cpu 4 --memory 4 --mount "$${HOME}/ghq/:w" --mount "$${HOME}/.local/share/chezmoi/:w"

.PHONY: docker-build
docker-build:
	docker build -t dotfiles . --build-arg USERNAME="$$(whoami)"

.PHONY: docker-run
docker-run:
	docker run -it -v "$$(pwd):/home/$$(whoami)/.local/share/chezmoi" dotfiles /bin/bash --login
