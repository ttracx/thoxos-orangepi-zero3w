<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 THOX.ai LLC
-->

# ThoxOS firmware notes — Orange Pi Zero 3W

This directory does not build firmware and does not contain blobs.
It records what ThoxOS leaves in the vendor image, what it refuses to
start, and what a later package may install outside git.

Board: Orange Pi Zero 3W.
SoC: Allwinner A733 (`sun60iw2`).
Image this tree assumes, and does not rebuild:

`Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98`

Referenced, not copied:

- Firmware blobs, if any, stay in the vendor image or in
  <https://github.com/orangepi-xunlong/firmware>.
  ThoxOS does not vendor those files and does not redistribute them.
- Toolchain branches live at
  <https://github.com/orangepi-xunlong/toolchain>.
  This tree does not pin a tarball URL.
- Bootloader lineage is
  <https://github.com/orangepi-xunlong/u-boot-orangepi>.
  `boot0` stays in the vendor image. It is not produced here.

Machine-readable list: [manifest.yaml](manifest.yaml).

## Subsystems

| Subsystem | Owner | Source | ThoxOS redistributes | ThoxMini runtime | ThoxClip runtime |
| --- | --- | --- | --- | --- | --- |
| boot0 | Xunlong vendor image | Stays inside the named image. Lineage: `orangepi-xunlong/u-boot-orangepi`. Not built here. | NO | Required. Do not replace in this tree. | Required. Do not replace in this tree. |
| Wi-Fi 6 / Bluetooth 5.4 | Module cited by press as Cdtech 20800D8-00. mac80211 driver name is UNKNOWN (not asserted). | Vendor DTS `&rfkill` (`allwinner,sunxi-rfkill`). Blobs, if the image has them, are referenced from `orangepi-xunlong/firmware` only. | NO | Board radio may be used for IP. Matter, Thread, and Zigbee are the carrier ESP32-C6, not this firmware. | Required. BT 5.4 is the ThoxClip link. |
| NPU | Allwinner vendor userspace. Not rehosted here. | Vendor DTS node `&npu`. Libraries, when installed, belong in `/usr/lib/thox/npu` and must not be committed. | NO | Optional. `thoxos-npu-probe` fails closed until both the node and a library exist. | Same as ThoxMini. |
| GPU (Imagination BXM-4-64 MC1) | Imagination closed driver (OpenGL ES 3.2, Vulkan 1.3, OpenCL 3.0). | Vendor stack. Not started. See [gpu/README.md](gpu/README.md). | NO | Do not start. No display server. | Do not start. No display server. |
| E902 (Xuantie, up to 200 MHz) | Vendor arisc / remoteproc. | Vendor image. No firmware blob in this tree. See [e902/README.md](e902/README.md). | NO | Leave the vendor firmware. Do not route MagLink or ESP32 through it. | Same as ThoxMini. |
| PMIC AXP8191 | In the vendor kernel. Name is the vendor DTS name. | Kernel regulator driver. Rails used by the radio include `axp8191-bldo5` and `cldo1` at 1.8 V. | NO (no separate blob) | Required. | Required. |

Details: [wifi/README.md](wifi/README.md), [npu/README.md](npu/README.md),
[gpu/README.md](gpu/README.md), [e902/README.md](e902/README.md).
