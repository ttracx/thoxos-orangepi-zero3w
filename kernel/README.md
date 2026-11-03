# ThoxOS kernel fragment (Orange Pi Zero 3W)

Linux pin: **6.6.98**. Tree:

https://github.com/orangepi-xunlong/linux-orangepi

branch `orange-pi-6.6-sun60iw2` (`Makefile`: `VERSION = 6`, `PATCHLEVEL = 6`, `SUBLEVEL = 98`).

Board: Orange Pi Zero 3W, SoC Allwinner A733 (`sun60iw2` / `sun60iw2p1`).
Image base: Orange Pi Ubuntu Jammy server, revision 1.0.2. In
`orangepi-build` (branch `next`) that is board file
`external/config/boards/orangepizero3w.conf` (`REVISION="1.0.2"`,
`BOARDFAMILY="sun60iw2"`,
`BOOT_FDT_FILE="allwinner/sun60i-a733-orangepi-zero3w.dtb"`).
`external/config/sources/families/sun60iw2.conf` selects, for
`BRANCH=current` and this board,
`LINUXCONFIG="linux-sun60iw2-current-a733"` and
`KERNELBRANCH="branch:orange-pi-6.6-sun60iw2"`.

ThoxMini and ThoxClip share this kernel. The carrier difference is only
the two files under `dts/`.

## Not a defconfig

This command does **not** work. There is no such target:

```
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- thoxos_opi_zero3w_defconfig
```

The vendor branch has `arch/arm64/configs/defconfig` (generic arm64) and
`virt.config`. Neither is the Zero 3W image config. Do not merge onto
the generic `defconfig`.

Merge `thoxos_opi_zero3w.fragment` onto the A733 config the image build
uses:

`orangepi-build/external/config/kernel/linux-sun60iw2-current-a733.config`

From a `linux-orangepi` checkout of `orange-pi-6.6-sun60iw2`:

```
scripts/kconfig/merge_config.sh -m \
  /path/to/linux-sun60iw2-current-a733.config \
  /path/to/bsp/thoxos-opi-zero3w/kernel/thoxos_opi_zero3w.fragment

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
```

`-m` writes `.config`. `olddefconfig` applies `select`s and drops
symbols whose dependencies are still off. After that, diff the fragment
against `.config`. A dropped line is a failed merge, not success.

`CONFIG_LOCALVERSION="-thoxos"` produces release `6.6.98-thoxos`.
Do not move `SUBLEVEL`.

The fragment does not set NPU, Wi-Fi, or GPU symbols. Confirm the merged
`.config` still has the vendor AIC8800 and `CONFIG_AW_NNA_VIP` lines.
Details: `FRAGMENT-NOTES.md`.

## DTS include

`dts/sun60i-a733-thoxmini-opi3w.dts` and
`dts/sun60i-a733-thoxclip-opi3w.dts` contain only:

```
#include "sun60i-a733-orangepi-zero3w.dts"
```

That basename is the vendor board file

`arch/arm64/boot/dts/allwinner/sun60i-a733-orangepi-zero3w.dts`

(~4100 lines), which includes `sun60iw2p1.dtsi`. The ThoxOS files set
`model` and `compatible` and add a `thox-carrier` node. They do not
copy the vendor dts and do not redefine `&npu` or `&rfkill`.

They are not buildable from this directory. Copy steps: `dts/README.md`.

## Modules

`modules.list` is what the image expects available (built-in or `.ko`).
`=y` entries do not produce a module file.
