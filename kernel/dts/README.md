# Carrier DTS fragments

`sun60i-a733-thoxmini-opi3w.dts` and `sun60i-a733-thoxclip-opi3w.dts`
are not bootable from this directory. Each file is a wrapper:

```
#include "sun60i-a733-orangepi-zero3w.dts"
```

`dtc` resolves that basename only when the wrapper sits in the same
directory as the vendor board dts. The vendor file is ~4100 lines, includes
`sun60iw2p1.dtsi`, and is not copied into this tree.

The wrappers do not repeat `/dts-v1/;`. The vendor file supplies it.
They only override `/` `model` and `compatible`, and add `thox-carrier`.

Checked on branch `orange-pi-6.6-sun60iw2`: the vendor file's root
compatible is currently `"xunlong,orangepi-4-pro", "arm,sun60iw2p1"`
and it has no `model` property. The wrapper replaces that property.
It does not keep `arm,sun60iw2p1`. Root compatible is board identity;
per-device compatibles inside the included dts are unchanged.

## Copy

From a checkout of `linux-orangepi` at `orange-pi-6.6-sun60iw2`:

```
cp /path/to/bsp/thoxos-opi-zero3w/kernel/dts/sun60i-a733-thoxmini-opi3w.dts \
   /path/to/bsp/thoxos-opi-zero3w/kernel/dts/sun60i-a733-thoxclip-opi3w.dts \
   arch/arm64/boot/dts/allwinner/
```

In `arch/arm64/boot/dts/allwinner/Makefile`, next to the existing

```
dtb-$(CONFIG_ARCH_SUNXI) += sun60i-a733-orangepi-zero3w.dtb
```

add:

```
dtb-$(CONFIG_ARCH_SUNXI) += sun60i-a733-thoxmini-opi3w.dtb
dtb-$(CONFIG_ARCH_SUNXI) += sun60i-a733-thoxclip-opi3w.dtb
```

Build in-tree, after the config merge in `../README.md`:

```
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
  dtbs
```

Outputs:

```
arch/arm64/boot/dts/allwinner/sun60i-a733-thoxmini-opi3w.dtb
arch/arm64/boot/dts/allwinner/sun60i-a733-thoxclip-opi3w.dtb
```

Boot with one of those, not with `sun60i-a733-orangepi-zero3w.dtb`.
U-Boot on the vendor image looks for
`allwinner/sun60i-a733-orangepi-zero3w.dtb`
(`BOOT_FDT_FILE` in `orangepizero3w.conf`). Point the boot script at
the ThoxOS dtb or the carrier node is absent.

Carrier GPIOs are logical names only. Physical lines are in
`hardware/pin-contract.json`. Do not fill in Allwinner pin numbers here.
