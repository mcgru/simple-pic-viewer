.PHONY: help build docker docker-static bump deb commit

help:
	@echo 'Available targets:'
	@echo '  make build         — build binary locally'
	@echo '  make docker        — build binary via Docker (Dockerfile.ubuntu)'
	@echo '  make docker-static — build binary via Docker static (Dockerfile.ubuntu.static)'
	@echo '  make bump VER=X.Y.Z — bump version in all files, commit and tag'
	@echo '  make deb           — build .deb package (builds binary first)'
	@echo '  make commit msg="..."  — git add -A && git commit'

build:
	./build.sh

docker:
	docker build --network host -f Dockerfile.ubuntu -t simple-pic-viewer-builder .
	docker run --rm --network host -v "$$(pwd):/app" simple-pic-viewer-builder

docker-static:
	docker build --network host -f Dockerfile.ubuntu.static -t simple-pic-viewer-builder .
	docker run --rm --network host -v "$$(pwd):/app" simple-pic-viewer-builder

bump:
	@test -n "$(VER)" || { echo 'Usage: make bump VER=X.Y.Z'; exit 1; }
	./bump-version.sh $(VER)

deb: build
	./makedeb.sh local simple-pic-viewer

commit:
	git add -A
	@test -n "$(msg)" && git commit -m "$(msg)" || git commit -m "quick update"
