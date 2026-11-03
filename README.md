# ThoxOS for Orange Pi Zero 3W

Official board support for **ThoxMini** and **ThoxClip** when the compute module is an Orange Pi Zero 3W (Allwinner A733, `sun60iw2`).

This tree is the image recipe and the firmware contract. It is not a flashed card. The vendor root filesystem stays in the Orange Pi 1.0.2 archive. ThoxOS 1.0.0 overlays that root. It does not rebuild boot0 and it does not rewrite the partition table.

## Stamp

| | |
| --- | --- |
| Image id | `thoxos-opi3w-1.0.0` |
| RAUC compatible | `thoxos-opi3w` |
| Base | `Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98.7z` |
| Kernel | Linux 6.6.98, branch `orange-pi-6.6-sun60iw2` |
| Userspace | Ubuntu 22.04 jammy server |
| SKUs | `thoxmini` (4 GB floor), `thoxclip` (2 GB floor) |

Desktop images are rejected. The closed PowerVR BXM-4-64 driver has deadlocked a live compositor on this SoC. Resolute server 6.6.98 is an allowed alternate base, not the stamp. Kernel 5.15.147 is not the pin.

## Layout

```
boot/        U-Boot environment, boot.cmd, RAUC system.conf (inactive on v1)
kernel/      merge_config fragment and carrier DTS (includes the vendor dts)
firmware/    manifest and probes, no blobs
hardware/    carrier contract for ThoxMini and ThoxClip
image/       class definitions and rootfs overlay
build/       thoxos-image.sh
```

Upstream, not vendored here:

- https://github.com/orangepi-xunlong/linux-orangepi (`orange-pi-6.6-sun60iw2`)
- https://github.com/orangepi-xunlong/u-boot-orangepi
- https://github.com/orangepi-xunlong/firmware
- https://github.com/orangepi-xunlong/toolchain
- https://github.com/orangepi-xunlong/OrangePi_Build

Vendor board device tree, included by the ThoxOS DTS and not copied into this repo:

`arch/arm64/boot/dts/allwinner/sun60i-a733-orangepi-zero3w.dts`

## Build

```sh
./build/thoxos-image.sh --check
./build/thoxos-image.sh \
  --sku thoxmini \
  --base /path/to/Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98.img \
  --out thoxos-thoxmini-opi3w-1.0.0.img
```

`--check` validates the tree and does not need a base image. A real `--base` must already be unpacked from the vendor `.7z` to a `.img`. The script copies the overlay into the vendor root, writes the SKU, and installs `boot.scr` when `mkimage` exists. It refuses desktop filenames. It refuses `--partition-rewrite`.

## What is still bench work

- Physical 40-pin silkscreen is not frozen. `hardware/pin-contract.json` is logical nets only.
- Wi-Fi, Bluetooth, NPU, GPU, boot0, and E902 blobs are not redistributed.
- RAUC A/B is specified and not active until `sfdisk -d` on a real card says the vendor map is safe to replace.
- Mainline `sun60i-a733` is not this boot path.

## License

Apache-2.0. Copyright 2026 THOX.ai LLC. The THOX marks are not covered by the license. Vendor Orange Pi sources remain under their own licenses.
