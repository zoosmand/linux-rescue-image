.DEFAULT_GOAL := build

.PHONY: build export clean cleanup

build:
	./scripts/build.sh

export:
	./scripts/export.sh

# Purge live-build state before removing the exported and packaged images.
clean:
	@test "$$(id -u)" -eq 0 || { echo 'Run sudo make clean.' >&2; exit 1; }
	lb clean --purge
	rm -rf -- artifacts
	rm -f -- live-image-* build.log

cleanup: clean
