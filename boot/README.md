# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC

# ThoxOS boot — Orange Pi Zero 3W

Board: Orange Pi Zero 3W. SoC: Allwinner A733. Platform: sun60iw2.
Vendor U-Boot tree (use this; do not fork a from-scratch SPL):
https://github.com/orangepi-xunlong/u-boot-orangepi
branch `v2018.05-sun60iw2`, defconfig `sun60iw2p1_t736_defconfig`.
orangepi-build also points `MAINLINE_UBOOT_SOURCE` at
`https://gitee.com/orangepi-xunlong/u-boot-orangepi.git`. Same branch.

Vendor images are Ubuntu jammy or resolute with Linux 5.15.147 (legacy,
`orange-pi-5.15-sun60iw2`) or 6.6.98 (current, `orange-pi-6.6-sun60iw2`).
`orangepizero3w.conf` sets `KERNEL_TARGET="current legacy"`,
`BOOTCONFIG="sun60iw2p1_t736_defconfig"`,
`BOOT_FDT_FILE="allwinner/sun60i-a733-orangepi-zero3w.dtb"`,
`OVERLAY_PREFIX=sun60i-a733` on this board, and `REVISION="1.0.2"`.

Chosen base: Orangepizero3w_1.0.2 Ubuntu jammy server, Linux 6.6.98.
ThoxOS image id: `thoxos-opi3w-1.0.0`. This directory overlays that image.
It does not generate a new SPL, boot0, or TOC.

## Boot chain

Order is fixed. Each stage is what actually hands off on this SoC.

1. BROM. Allwinner A733 mask ROM. It is not in the vendor tree and not in
   this tree. We do not replace it.
2. Vendor boot0 / TOC. Stays from the Orange Pi image. Not rebuilt here.
   boot0 is a prebuilt pack-uboot blob (`boot0_sdcard_orangepizero3w.fex`,
   or `boot0_sdcard_a733.fex` if the board file is absent). The TOC is
   `boot_package.fex`, produced upstream by `dragonsecboot -pack
   boot_package.cfg` around the vendor U-Boot binary. `ATF_COMPILE="no"`
   in the sun60iw2 family. This is not mainline `u-boot-sunxi-with-spl.bin`.
3. U-Boot. The vendor binary already in that boot package, built from
   `sun60iw2p1_t736_defconfig` (32-bit ARM, `arm-linux-gnueabi-`,
   `CONFIG_SYS_TEXT_BASE=0x4A000000`, `CONFIG_MACH_SUN60IW2=y`,
   `CONFIG_DISTRO_DEFAULTS=y`, `CONFIG_ENV_IS_IN_EXT4=y`).
   `CONFIG_DEFAULT_DEVICE_TREE` in that file is `sun60iw2p1-soc-system`.
   That is U-Boot's own control DT, not the Linux board DTB.
   ThoxOS does not replace this binary in 1.0.0. The only U-Boot change
   tracked here is an environment overlay plus
   `thox_opi_zero3w_defconfig.fragment` for a later rebuild.
4. extlinux or `boot.scr`. Distro boot (because `CONFIG_DISTRO_DEFAULTS=y`)
   tries `extlinux/extlinux.conf` and then `boot.scr`. v1 does not install
   extlinux.conf, so this step is `boot.scr`. The defconfig does not set
   `CONFIG_BOOTCOMMAND` and does not define `bootcmd_orangepi`.
5. Kernel `Image` plus a ThoxOS DTB, or the vendor `uImage` plus
   `sun60i-a733-orangepi-zero3w.dtb` if the ThoxOS files are absent.
   See `boot.cmd`.
6. Ubuntu 22.04 root with the ThoxOS overlay. v1 is still the vendor single
   ext4 root. RAUC dual-slot is specified and gated; see `slots.md`.

## boot.scr

`boot.cmd` is applied on the build host, not on the board:

```
mkimage -C none -A arm64 -T script -d boot.cmd boot.scr
```

The vendor bootscript comment uses `-A arm`. The architecture field is not
executed for a script image. ThoxOS uses the command above.

Install the resulting `boot.scr` into the vendor image's existing `/boot`.
Do not move U-Boot sectors. Do not dd boot0 or `boot_package.fex`. The
Linux user manual for this board says the image has one ext4 partition and
no separate BOOT partition, so `/boot` is a directory on that root.

Before replacing `/boot/boot.scr`, copy it to `/boot/boot.scr.vendor`.
`boot.cmd` sources that copy if the ThoxOS kernel or DTB is missing, or if
`booti` / `bootm` returns. It then tries `bootcmd_orangepi` only when that
variable exists, and otherwise `run bootcmd`. A guard variable stops
`bootcmd` from sourcing this script forever.

`boot.cmd` loads whatever device distro boot already selected (`devtype`,
`devnum`, `prefix`). It does not hard-code `mmc 0`.

DTB pick, first hit wins:

- `sun60i-a733-${thox_sku}-opi3w.dtb` under `dtb/allwinner/`, `dtb/`, or
  the prefix itself
- else `sun60i-a733-orangepi-zero3w.dtb` in those same places

Kernel pick:

- `${prefix}Image` via `booti` (ThoxOS raw arm64 image)
- else `${prefix}uImage` via `bootm` (what `boot-sun60iw2.cmd` uses)

Load addresses are the vendor variables `kernel_addr_r`, `fdt_addr_r`, and
`ramdisk_addr_r`. They are not assigned here. If either kernel or fdt
address is unset, the script does not invent one and falls through.
`load_addr` is set to `0x43100000` only when empty, because that is the
scratch address in the published `boot-sun60iw2.cmd`, used for env import
and for sourcing `boot.scr.vendor`. Armbian relocates `kernel_addr_r` to
`0x41000000` because it considers the vendor defaults cramped for a kernel
past about 30 MB. That relocation is not applied here: it is not what the
1.0.2 jammy image's U-Boot was measured to use. If a ThoxOS `Image` fails
to boot at the vendor address, fix it with a measured address, not a guess.

Command line: if `bootargs` is already set, append

```
quiet loglevel=4 console=ttyS0,115200 console=tty1 thox.sku=${thox_sku} thox.carrier=opi3w cgroup_enable=memory swapaccount=1
```

If `bootargs` is empty, synthesize `root=` the way `boot-sun60iw2.cmd`
does (PARTUUID of partition 1, `rootwait`, `rootfstype`, `clk_ignore_unused`,
and the vendor `docker_optimizations=on` cgroup flags) and then append the
same string. The append is how `loglevel=4` wins over the vendor
`verbosity` loglevel. `console=ttyS0,115200` matches the vendor bootscript.
An Android log that shows `ttyAS0` is a different boot path and is not used.

`thox_sku` defaults to `thoxmini` when unset. The environment and
`/boot/orangepiEnv.txt` can override it. `orangepiEnv.txt` is imported
after `thoxos.env.txt`.

## Environment overlay

`env/thoxos.env.txt` is merged, not a full environment. Installed path:
`/boot/thoxos.env.txt`. Keys: `thox_sku`, `thox_image_id=thoxos-opi3w-1.0.0`,
`bootdelay=1`, `stderr=serial`.

`CONFIG_ENV_IS_IN_EXT4=y` is set. The defconfig does not name the ext4 env
file. Importing the text file from `boot.cmd` does not replace that store
and does not change the bootdelay of the boot currently in progress.
`CONFIG_BOOTDELAY=1` in the fragment applies only when U-Boot is rebuilt
with the fragment.

`CONFIG_PREBOOT="echo THOXOS ${thox_image_id}"` is likewise a rebuild-only
line. `${thox_image_id}` expands from the environment at run time.

## A/B

v1 keeps the vendor single root. No second root, no RAUC slot, no U-Boot
slot select.

RAUC dual-slot is specified in `slots.md` and `rauc/system.conf`
(`compatible=thoxos-opi3w`, slots `rootfs.0` / `rootfs.1`). It is gated:
the system.conf header says it is not active on the v1 vendor-layout image
and is installed only when the production GPT is measured. The health gate
is userspace (`thoxos-health.service`), not U-Boot A/B.

The build script must refuse to rewrite the partition table unless
`--partition-rewrite` is passed. That flag is unsupported in 1.0.0.
See `slots.md`.

## What this directory does not do

- Does not build or emit boot0, TOC, `boot_package.fex`, or SPL.
- Does not change the Boot ROM.
- Does not set `CONFIG_DEFAULT_DEVICE_TREE`.
- Does not invent kernel load addresses.
- Does not claim the pack-uboot seek numbers are the 1.0.2 image map.
- Does not install `rauc/system.conf` onto the single-root jammy image.
