#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
command -v mkpasswd >/dev/null 2>&1 || {
    echo 'Install the password hashing tool: sudo apt install whois' >&2
    exit 1
}
umask 077
hash_file=config/includes.chroot/root/.rescue-password.hash
temporary_file=$(mktemp "${hash_file}.XXXXXX")
trap 'rm -f "$temporary_file"' EXIT HUP INT TERM
# mkpasswd prompts without echoing; only the hash is written to disk.
mkpasswd --method=yescrypt > "$temporary_file"
test -s "$temporary_file"
mv "$temporary_file" "$hash_file"
echo 'Rescue password hash saved. Rebuild the image to apply it.'
