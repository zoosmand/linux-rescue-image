#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this script as root on a Debian 13 amd64 build host.' >&2
    exit 1
fi
command -v lb >/dev/null 2>&1 || {
    echo 'Install live-build first: apt install live-build' >&2
    exit 1
}
lb config
lb build
./scripts/export.sh
