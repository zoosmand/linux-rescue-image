#!/usr/bin/env python3
"""Package a completed netboot build for deployment under /tftpboot."""

import ipaddress
import os
from pathlib import Path
import re
import shutil
import tarfile
import tempfile


def main():
    try:
        address = ipaddress.IPv4Address(os.environ.get("IP_ADDR", ""))
    except ipaddress.AddressValueError:
        raise SystemExit("Supply an IPv4 address: make pack IP_ADDR=192.0.2.10")
    try:
        port = int(os.environ.get("TCP_PORT", "80"))
        if not 1 <= port <= 65535:
            raise ValueError
    except ValueError:
        raise SystemExit("TCP_PORT must be an integer between 1 and 65535")
    fetch_url = f"http://{address}:{port}/filesystem.squashfs"

    root = Path(__file__).resolve().parent.parent
    source_tree = root / "tftpboot"
    squashfs = root / "binary/live/filesystem.squashfs"
    for path in (source_tree / "live.cfg", source_tree / "live/vmlinuz",
                 source_tree / "live/initrd.img", squashfs):
        if not path.is_file():
            raise SystemExit(f"Missing build output: {path}. Run make build first.")

    output = root / "artifacts"
    output.mkdir(exist_ok=True)
    archive = output / "rescue-tftpboot.tgz"
    # Stage only the package; do not alter the host's /tftpboot or build outputs.
    with tempfile.TemporaryDirectory(prefix="rescue-pack-") as temporary:
        stage = Path(temporary)
        tree = stage / "tftpboot"
        shutil.copytree(source_tree, tree, symlinks=True)
        (tree / "rescue").mkdir(exist_ok=True)
        shutil.copyfile(squashfs, tree / "rescue/filesystem.squashfs")
        (tree / "rescue/filesystem.squashfs").chmod(0o644)
        menu = tree / "live.cfg"
        lines = []
        entries = 0
        for line in menu.read_text().splitlines():
            if re.match(r"\s*append\s+", line, re.IGNORECASE):
                line = re.sub(r"\s+fetch=\S+", "", line)
                line += f" fetch={fetch_url}"
                entries += 1
            lines.append(line)
        if not entries:
            raise SystemExit("No APPEND entries found in tftpboot/live.cfg")
        menu.write_text("\n".join(lines) + "\n")
        # Publish only a fully written archive.
        handle, pending = tempfile.mkstemp(prefix=".rescue-tftpboot-", dir=output)
        os.close(handle)
        try:
            with tarfile.open(pending, "w:gz") as package:
                package.add(tree, arcname="tftpboot")
            os.chmod(pending, 0o644)
            os.replace(pending, archive)
        finally:
            Path(pending).unlink(missing_ok=True)
    print(f"Created {archive}")
    print(f"TFTP root: /tftpboot; HTTP root: /tftpboot/rescue (port {port})")


if __name__ == "__main__":
    main()
