# Debian rescue image (PXE and ISO)

An amd64 Debian 13 (Trixie) live environment for legacy BIOS and x86-64 UEFI
PXE clients. Your existing bootloader loads the same kernel and initramfs in
either mode; live-boot fetches the SquashFS root filesystem over HTTP into RAM.
The package list includes storage, filesystem, recovery, diagnostic and boot
repair tools, with GRUB binaries for both BIOS and UEFI repair.

Cloud clients include `aws` and `az` from Debian's `awscli` and `azure-cli`
packages, and `gcloud` from Google's signed APT repository. The Google CLI is
installed by a build hook for both PXE and ISO images; builds need access to
`packages.cloud.google.com` in addition to Debian mirrors. Its version follows
the vendor repository at build time. Configure cloud authentication after boot.

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

## Rescue ISO

Build a hybrid ISO with the same packages and SSH configuration:

```sh
sudo make iso
```

The output is `artifacts/rescue-amd64.iso`, with its checksum in
`artifacts/rescue-amd64.iso.sha256`. The ISO includes BIOS (ISOLINUX) and
x86-64 UEFI (GRUB) bootloaders and its own root filesystem, so it does not
require your HTTP server. Use it as virtual CD/DVD media or write the hybrid
image to a USB drive.

ISO builds use a separate `.iso-build/` directory and leave the PXE build and
exports available. Each ISO build starts with fresh build state; `make clean`
also purges the ISO workspace and output. Boot-test the ISO under both BIOS and
UEFI before using it for recovery.

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
The generated `tftpboot/live.cfg` does not contain your HTTP server's address.
If you use that menu, add `fetch=http://YOUR_SERVER_IP/rescue/filesystem.squashfs`
to its `append` lines as well. Loading only the kernel and initramfs is not
enough to boot the live environment.
UEFI Secure Boot support is not validated by this project.

If boot reports "Unable to find a medium containing a live file system", run
`cat /proc/cmdline` at the initramfs prompt and confirm that `fetch=` contains
the correct numeric HTTP server address and path. From another machine, check
that the same URL returns the SquashFS file successfully. If the URL is present
and correct, add `debug=1` to the kernel parameters and inspect the preceding
network/download errors.

## File servers

OpenNTPD starts automatically with `-s` to attempt an immediate clock correction
at startup. Its NTP servers are configured in `/etc/openntpd/ntpd.conf`; provide
an override in `config/includes.chroot/etc/openntpd/ntpd.conf` if needed.

`tftpd-hpa` starts automatically and serves `/tftpboot` on UDP port 69.
Place files there with permissions that allow the `tftp` user to read them.
The server uses `--secure` to restrict serving to that directory; uploads of
new files are not enabled.

Python 3 includes the standard library HTTP server. To serve the same directory
over HTTP, start it manually:

```sh
python3 -m http.server 8000 --bind 0.0.0.0 --directory /tftpboot
```

Files and server state created during the live session disappear on reboot.

## Access

The image contains a `rescue` account with passwordless sudo. Console autologin
is disabled; set its console login password locally before rebuilding:

```sh
sudo apt install whois
make password
```

The command prompts for the password without echoing it and saves a yescrypt
hash in an ignored local file. Run `sudo make password` if the configuration
directory is root-owned. Without a configured password, console password login
for rescue is disabled. The hash is applied to `/etc/shadow` during the build;
the temporary input file is removed from the image. `make clean` retains the
local password input. Anyone who can download the image can extract its shadow
hash, so use a long password unique to this rescue environment.

SSH starts automatically and accepts public keys only for both `root` and
`rescue`. Put their shared public key in
`config/includes.chroot/root/.ssh/authorized_keys`; the build copies that file
to rescue's home directory with the correct ownership and permissions. It is
intentionally empty until you add a key, so neither account currently has a
usable SSH login. Root SSH password login and all SSH password/keyboard
interactive authentication remain disabled. Private keys never belong in the
image. Host keys are generated on each boot rather than shared between machines.

After setting the password or changing keys, run `sudo make clean` followed by
`sudo make build` and/or `sudo make iso`.

Both root and rescue have `.vimrc`, `.tmux.conf`, and `.bash_aliases` files in their home
directories. Customize the corresponding files in `config/includes.chroot/root/`
and `config/includes.chroot/home/rescue/` before building.

The root filesystem has a temporary writable overlay; session changes disappear
at reboot. Repair commands can still modify local disks explicitly.

## Validation

Boot the artifacts on one legacy BIOS client and one UEFI client. Confirm DHCP,
HTTP retrieval, console password login, passwordless sudo and availability
of storage tools. After adding a public key, confirm SSH access as both root
and rescue, and rejection of SSH password logins for both accounts.
A successful image build alone does not verify firmware boot compatibility.

References: [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html)
and [live-boot parameters](https://manpages.debian.org/trixie/live-boot-doc/live-boot.7.en.html).
