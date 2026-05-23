.PHONY: help build docker docker-static bump deb commit

help:
	@echo 'Available targets:'
	@echo '  make build         — build binary locally'
	@echo '  make docker        — build binary via Docker (Dockerfile.ubuntu)'
	@echo '  make docker-static — build binary via Docker static (Dockerfile.ubuntu.static)'
	@echo '  make bump [X.Y.Z]  — calculate version from commits, or use explicit'
	@echo '  make deb           — build .deb package (builds binary first)'
	@echo '  make commit msg="..."  — git add -A && git commit'
	@echo '  make install       — install binary to ~/.local/bin'

build:
	./build.sh

docker:
	docker build --network host -f Dockerfile.ubuntu -t simple-pic-viewer-builder .
	docker run --rm --network host -v "$$(pwd):/app" simple-pic-viewer-builder

docker-static:
	docker build --network host -f Dockerfile.ubuntu.static -t simple-pic-viewer-builder .
	docker run --rm --network host -v "$$(pwd):/app" simple-pic-viewer-builder

ifeq (bump,$(firstword $(MAKECMDGOALS)))
  BUMP_VER := $(word 2,$(MAKECMDGOALS))
  ifneq (,$(BUMP_VER))
    $(eval $(BUMP_VER):;@true)
  endif
endif

bump:
	@if [ -n "$(BUMP_VER)" ]; then \
		./bump-version.sh $(BUMP_VER); \
	else \
		VER=$$(./calc-version.sh) && echo "==> Calculated: $$VER" && ./bump-version.sh $$VER; \
	fi

deb: build
	./makedeb.sh local simple-pic-viewer

commit:
	git add -A
	@test -n "$(msg)" && git commit -m "$(msg)" || git commit -m "quick update"

install: build
	@if [ "$$(id -u)" -eq 0 ]; then \
		DEST="/usr/local/bin"; \
	else \
		DEST="$$HOME/.local/bin"; \
		mkdir -p "$$DEST"; \
	fi; \
	cp simple-pic-viewer "$$DEST/simple-pic-viewer" && \
	chmod 755 "$$DEST/simple-pic-viewer" && \
	echo "==> Installed: $$DEST/simple-pic-viewer" && \
	if [ "$$(id -u)" -ne 0 ] && ! echo "$$PATH" | grep -q "$$HOME/.local/bin"; then \
		echo "=== Hint: add ~/.local/bin to your PATH ==="; \
		echo '  export PATH="$$HOME/.local/bin:$$PATH"'; \
		if ! grep -qs "HOME/.local/bin" "$$HOME/.bashrc" 2>/dev/null; then \
			echo "  Or run: echo 'export PATH=\"\$$HOME/.local/bin:\$$PATH\"' >> ~/.bashrc"; \
		fi; \
	fi
