# Debian PXE rescue image

An amd64 Debian 13 (Trixie) live environment for legacy BIOS and x86-64 UEFI
PXE clients. Your existing bootloader loads the same kernel and initramfs in
either mode; live-boot fetches the SquashFS root filesystem over HTTP into RAM.
The package list includes storage, filesystem, recovery, diagnostic and boot
repair tools, with GRUB binaries for both BIOS and UEFI repair.

## Build

On a Debian 13 amd64 host with root access and internet connectivity:

```sh
sudo apt update
sudo apt install live-build make
sudo make build
```

The exported files are `artifacts/vmlinuz`, `artifacts/initrd.img`,
`artifacts/filesystem.squashfs` and `artifacts/SHA256SUMS`.
To export an already completed build without rebuilding, run
`sudo make export`. Netboot kernel and initramfs inputs are in
`tftpboot/live/`; the SquashFS input is in `binary/live/`.
The configuration uses the current Trixie repositories, including security
updates. Debian 13.7 is the starting release target, not a frozen package
snapshot: later builds can contain newer updates.

For a fresh rebuild after changing the configuration:

```sh
sudo make clean
sudo make build
```

`make build` is the default target and also exports the result. `make export`
copies an existing build without rebuilding. `make clean` (also available as
`make cleanup`) purges live-build state and caches, exported artifacts, packaged
images and the build log. Project configuration and scripts are retained.

## Serve and boot

Copy the kernel and initramfs to your TFTP server under `rescue/` and serve the
SquashFS from `http://192.0.2.10/rescue/filesystem.squashfs`. Replace the example
IP with your HTTP server's actual numeric address. A numeric address avoids
early-boot DNS dependencies. RAM must accommodate the downloaded filesystem
and the running system.

Legacy BIOS PXELINUX entry:

```text
LABEL rescue
  MENU LABEL Debian rescue
  KERNEL rescue/vmlinuz
  INITRD rescue/initrd.img
  APPEND boot=live components ip=dhcp hostname=rescue username=rescue fetch=http://192.0.2.10/rescue/filesystem.squashfs
```

UEFI GRUB entry, with paths relative to the TFTP root:

```text
menuentry 'Debian rescue' {
    linux /rescue/vmlinuz boot=live components ip=dhcp hostname=rescue username=rescue fetch=http://192.0.2.10/rescue/filesystem.squashfs
    initrd /rescue/initrd.img
}
```

These entries use your existing PXE bootloader and DHCP/TFTP configuration.
UEFI Secure Boot support is not validated by this project.

## Access

The local console uses the live-config `rescue` account with its default live
session login and sudo behavior. SSH starts automatically and accepts public
keys only. Root's `config/includes.chroot/root/.ssh/authorized_keys` is
intentionally empty; add public keys there before building a final release.
Until then there is no usable SSH login. Private keys never belong in the image.
Host keys are generated on each boot rather than shared between machines.

The root filesystem has a temporary writable overlay; session changes disappear
at reboot. Repair commands can still modify local disks explicitly.

## Validation

Boot the artifacts on one legacy BIOS client and one UEFI client. Confirm DHCP,
HTTP retrieval, local sudo access and availability of storage tools. After
adding a public key, confirm root SSH access and rejection of password logins.
A successful image build alone does not verify firmware boot compatibility.

References: [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html)
and [live-boot parameters](https://manpages.debian.org/trixie/live-boot-doc/live-boot.7.en.html).
