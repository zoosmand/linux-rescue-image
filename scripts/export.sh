#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

# Netboot builds place the boot files in the TFTP tree.
for source_file in tftpboot/live/vmlinuz tftpboot/live/initrd.img binary/live/filesystem.squashfs; do
    if [ ! -f "$source_file" ]; then
        echo "Missing build output: $source_file. Run scripts/build.sh first." >&2
        exit 1
    fi
done

mkdir -p artifacts
# Dereference live-build's versioned kernel and initramfs symlinks.
cp -L tftpboot/live/vmlinuz artifacts/vmlinuz
cp -L tftpboot/live/initrd.img artifacts/initrd.img
cp binary/live/filesystem.squashfs artifacts/filesystem.squashfs
(cd artifacts && sha256sum vmlinuz initrd.img filesystem.squashfs > SHA256SUMS)
