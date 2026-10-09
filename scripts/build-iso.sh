#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(id -u)" -ne 0 ]; then
    echo 'Run sudo make iso on a Debian 13 amd64 build host.' >&2
    exit 1
fi
command -v lb >/dev/null 2>&1 || {
    echo 'Install live-build first: apt install live-build' >&2
    exit 1
}

# Keep ISO stages separate so the completed PXE build remains exportable.
mkdir -p .iso-build
if [ -d .iso-build/.build ]; then
    (cd .iso-build && lb clean --purge)
fi
rm -rf -- .iso-build/auto .iso-build/config
mkdir -p .iso-build/config
cp -a auto .iso-build/auto
for config_dir in package-lists includes.chroot hooks; do
    cp -a "config/$config_dir" .iso-build/config/
done
(
    cd .iso-build
    lb config --binary-images iso-hybrid --bootloaders 'syslinux grub-efi' \
        --bootappend-live 'boot=live components hostname=rescue username=rescue'
    lb build
)
mkdir -p artifacts
cp .iso-build/live-image-amd64.hybrid.iso artifacts/rescue-amd64.iso
(cd artifacts && sha256sum rescue-amd64.iso > rescue-amd64.iso.sha256)
