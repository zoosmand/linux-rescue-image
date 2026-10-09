.DEFAULT_GOAL := build

.PHONY: build iso export password clean cleanup

password:
	./scripts/set-password.sh

build:
	./scripts/build.sh

iso:
	./scripts/build-iso.sh

export:
	./scripts/export.sh

# Purge live-build state before removing the exported and packaged images.
clean:
	@test "$$(id -u)" -eq 0 || { echo 'Run sudo make clean.' >&2; exit 1; }
	lb clean --purge
	@if [ -d .iso-build ]; then cd .iso-build && lb clean --purge; fi
	rm -rf -- .iso-build
	rm -rf -- artifacts
	rm -f -- live-image-* build.log

cleanup: clean
