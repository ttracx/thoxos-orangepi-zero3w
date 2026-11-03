# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC

# Orange Pi Zero 3W slot map

Board: Orange Pi Zero 3W, Allwinner A733, platform sun60iw2.
ThoxOS image id: `thoxos-opi3w-1.0.0`.
Chosen base: Orangepizero3w_1.0.2 Ubuntu jammy server, Linux 6.6.98.
`orangepizero3w.conf` in orangepi-build `next` sets `REVISION="1.0.2"` and
`BOARDFAMILY="sun60iw2"`. This document does not claim a measured partition
dump of that image. No byte offsets below are a map of the shipped card.

## Bring-up (microSD, vendor-compatible)

v1 keeps the vendor single-root layout. ThoxOS only overlays files.
Bootloader sectors are untouched.

The Orange Pi Zero 3W user manual states that the Linux image has one ext4
partition and does not use a separate BOOT partition for the kernel. `/boot`
lives on that root filesystem. The v1 installer copies files into that
existing `/boot` and into the Ubuntu 22.04 root. It does not move U-Boot,
boot0, or the TOC.

What stays byte-for-byte from the Orange Pi image:

- Boot ROM. Mask ROM on the A733. Not in this tree.
- boot0. A prebuilt blob, not a U-Boot SPL built here. orangepi-build
  `sun60iw2.conf` copies `boot0_sdcard_${BOARD}.fex`, falling back to
  `boot0_sdcard_a733.fex`, from its pack-uboot blob directory.
- TOC / boot package. `uboot_custom_postprocess` in that same file packs
  vendor U-Boot with `dragonsecboot -pack boot_package.cfg` into
  `boot_package.fex`. `ATF_COMPILE="no"`. This tree does not run that pack
  step and does not generate a new SPL, boot0, or TOC.

Vendor U-Boot, when someone rebuilds it, is
https://github.com/orangepi-xunlong/u-boot-orangepi branch
`v2018.05-sun60iw2`, defconfig `sun60iw2p1_t736_defconfig`. The family file
also lists `https://gitee.com/orangepi-xunlong/u-boot-orangepi.git` as
`MAINLINE_UBOOT_SOURCE`. U-Boot is built with `arm-linux-gnueabi-` (32-bit
ARM). The kernel is arm64. v1 does not rebuild U-Boot. The defconfig
fragment in this directory is an overlay for a later rebuild, not an input
to the 1.0.0 image.

### What v1 writes

Only files inside the existing filesystem:

- `/boot/boot.scr`, produced on the build host from `boot.cmd`. Before
  replacing it, copy the image's existing `/boot/boot.scr` to
  `/boot/boot.scr.vendor`.
- `/boot/thoxos.env.txt` from `env/thoxos.env.txt`.
- ThoxOS kernel `Image` and, when built, `sun60i-a733-${thox_sku}-opi3w.dtb`,
  next to the vendor `uImage` and
  `dtb/allwinner/sun60i-a733-orangepi-zero3w.dtb`.
- Ubuntu 22.04 root overlay (userspace). Not specified in this directory
  beyond the RAUC config, which is not installed on v1.

No `extlinux.conf` is installed. With `CONFIG_DISTRO_DEFAULTS=y`, an
extlinux file would be tried before `boot.scr`. Leaving it absent is what
makes the vendor distro boot reach `boot.scr`.

### Build-system numbers that are not a measurement

These are recipes in source trees. They are not `sfdisk -d` output from
Orangepizero3w_1.0.2. Do not dd from them.

| Source | What it writes | Recorded seek | This is not |
| --- | --- | --- | --- |
| Armbian `config/sources/families/sun60iw2.conf` `write_uboot_platform` | `boot0_sdcard.fex`, then `boot_package.fex` | `bs=1k seek=8`, then `bs=1k seek=16400` | a dump of the jammy image |
| orangepi-build `sun60iw2.conf` `write_uboot_platform_ufs` | `boot0_ufs.fex`, then `boot_package.fex` | `dd seek=16`, then `dd seek=32800` (512-byte records; 32800*512 equals 16400 KiB) | the microSD image |
| orangepi-build `sun60iw2.conf` `write_uboot_platform_mtd` | `boot0_spinor_a733.fex`, then `boot_package.fex` | MTD offset 0, then 262144 | the microSD image |
| orangepi-build `MERGE_UBOOT` | optional 20 MiB merged blob | `bs=8k seek=1` and `bs=8k seek=2050` | the published image; the flag is off unless set |
| orangepi-build `sun60iw2.conf` | `OFFSET=32` | build-system rootfs start, in MiB, in that tree | a partition start measured on 1.0.2 |

`sun60iw2p1_t736_defconfig` also sets `CONFIG_SPINOR_LOGICAL_OFFSET=3296`,
`CONFIG_SPINOR_UBOOT_OFFSET=512`, and
`CONFIG_SUNXI_BOOT0_SDMMC_BACKUP_START_ADDR=2064`. Units are not interpreted
here. They are not a partition map.

`CONFIG_ANDROID_AB=y` is in that defconfig. `CONFIG_SUNXI_ANDROID_BOOT` is
commented out. ThoxOS 1.0.0 does not use Android A/B slot metadata.

## Production target (eMMC or UFS when stuffed)

Not built in 1.0.0. Specified so later images have one map. Applies only
after `sfdisk -d` (or the equivalent GPT dump) of the storage that will
actually be programmed.

GPT, four partitions, labels required:

| Order | Label | Size | Filesystem | Role |
| --- | --- | --- | --- | --- |
| 1 | `esp-or-boot` | 256 MiB | the boot filesystem the measured image uses | Shared boot. Kernel, DTB, `boot.scr`, `thoxos.env.txt`. Not a RAUC slot. |
| 2 | `rootfs.0` | not assigned in 1.0.0 | ext4 | RAUC slot A, `bootname=A` |
| 3 | `rootfs.1` | not assigned in 1.0.0 | ext4 | RAUC slot B, `bootname=B` |
| 4 | `data` | not assigned in 1.0.0 | ext4 | Persistent data. Not a RAUC slot. Not wiped by a root update. |

Rootfs and data sizes are omitted on purpose. Picking them before the
vendor map is measured would be a fake layout.

`boot/rauc/system.conf` matches this table (`compatible=thoxos-opi3w`).
It is installed only with this GPT. It is not copied onto the v1
single-root image, where `/dev/disk/by-partlabel/rootfs.0` does not exist.

The boot partition is shared. There is no per-slot bootloader. Health is
userspace: `thoxos-health.service` marks the booted slot good or failed.
U-Boot does not select A or B in 1.0.0. `CONFIG_ANDROID_AB` is not the
ThoxOS slot mechanism. RAUC's `bootloader=uboot` backend (BOOT_ORDER and
friends) is the production intent and is not driven by `boot.cmd` yet.

Boot0 and the TOC still have to sit in the unpartitioned prefix the Boot
ROM reads. A GPT that covers those sectors will not boot. That prefix is
exactly what has not been measured on the 1.0.2 image.

## Partition rewrite is refused

Shipping a rewritten GPT on top of Allwinner boot sectors is unsafe until
the vendor image map is measured with `sfdisk -d`.

The build script must refuse to rewrite the partition table unless
`--partition-rewrite` is passed. That flag is unsupported in 1.0.0. There
is no measured map to rewrite onto, and passing the flag does not make a
supported 1.0.0 image. A later version may honor it only after a checked-in
`sfdisk -d` of Orangepizero3w_1.0.2 is compared to the target disk and the
boot0/TOC prefix is shown to sit outside every new partition.

Until that measurement exists, the only legal image edit is a file overlay
on the vendor filesystem.
