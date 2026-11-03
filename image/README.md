# ThoxOS image overlay for Orange Pi Zero 3W

Copyright 2026 THOX.ai LLC

This directory is the payload that turns the official Orange Pi vendor image into ThoxOS 1.0.0. The top-level build driver lives outside this tree. It copies `overlay/` onto the unpacked vendor root using `rootfs-manifest.txt`, then enables the units listed for the SKU. This tree does not build the image and does not flash a board.

Image id: `thoxos-opi3w-1.0.0`
RAUC compatible string: `thoxos-opi3w`
SKUs: `thoxmini` (hostname `thoxmini`) and `thoxclip` (hostname `thoxclip`)

## Chosen base

Stamp file (not downloaded by this tree):

`Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98.7z`

- Kernel: 6.6.98 vendor (sun60iw2)
- Userspace: Ubuntu 22.04 jammy server
- Blobs live in https://drive.google.com/drive/folders/1sIFvfLJKRBOK06qqZ2_P0nx33mui3frB

Known vendor file names in that folder (name only): v1.0.2 jammy desktop xfce linux 5.15.147, jammy desktop xfce linux 6.6.98, jammy server linux 5.15.147, jammy server linux 6.6.98, resolute desktop xfce linux 6.6.98, resolute server linux 6.6.98. A backup folder also has 1.0.0 of the jammy set plus resolute 1.0.2. The stamp is 1.0.2 jammy server 6.6.98.

Not the default, and why:

- XFCE desktop images: the closed PowerVR BXM-4-64 driver can deadlock a live compositor. ThoxOS 1.0.0 is headless.
- Resolute server 6.6.98: allowed alternate base, not the stamp. Newer, less time on the bench.
- Vendor kernel 5.15.147: older line. 6.6.98 is the pin.

## What the overlay does

- Installs `/etc/thoxos-release` (`SKU=unset` until the build driver substitutes it) and `/etc/thoxos/sku.env` (default `SKU=thoxmini`, overwritten per SKU by the driver).
- First boot creates `/var/lib/thoxos`, notes machine-id by touching a stamp, and does not regenerate machine-id when one already exists. If `/etc/hostname` is missing or is a vendor default (`orangepi`, `orangepizero3w`, or `localhost`), it writes the SKU as the hostname. Any other hostname is left alone.
- Runs a headless portal stub that rewrites `/run/thoxos/status.json` every 30 seconds. It does not bind a port. The full portal is still planned in thoxos-core.
- Runs a health gate (`/usr/lib/thoxos/health.sh`) that a later RAUC hook can call. It writes `/run/thoxos/health` and does not reboot.
- Carrier, mesh, and gadget units are stubs. They do not invent GPIO numbers, do not wait on an ESP32, and do not generate WireGuard keys.
- NPU probe is a oneshot. Missing sysfs or empty `/usr/lib/thox/npu` does not fail the boot (`SuccessExitStatus=3 4`).

Class units (`classes/*/units.txt`):

- Both SKUs enable firstboot, portal, health, carrier, and the NPU probe.
- `thoxmini` also enables `thoxos-mesh.service`.
- `thoxclip` enables `thoxos-gadget.service` and does not enable a mesh radio unit.

`buildroot.config.fragment` is a layout placeholder. It is not a Buildroot config. The kernel fragment it points at is `../../kernel/thoxos_opi_zero3w.fragment`.

## What it refuses to do

- No apt packages that are not already in the vendor root. None are listed as optional. The overlay does not install packages.
- No network at first boot.
- No display manager, and no start of `graphical.target`.
- No partition rewrite. v1 keeps the vendor single-slot layout. RAUC A/B is specified and is not applied until the partition map is measured.
- No download of vendor blobs, no flash step, and no claim that an image has been flashed.
- No dependency on a file outside `image/` for the NPU probe logic.

## Check

From any working directory:

```
python3 /workspace/bsp/thoxos-opi-zero3w/image/validate.py
```

`ROOT` inside the validator is the parent of `image/` (the `thoxos-opi-zero3w` directory). A RAUC file is not required here.
