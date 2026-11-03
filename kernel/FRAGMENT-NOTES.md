# Fragment notes

`thoxos_opi_zero3w.fragment` only sets symbols that are mainline Kconfig
on 6.6.98, plus `CONFIG_MD=y` because `BLK_DEV_DM` depends on `MD` and
the vendor A733 config has `# CONFIG_MD is not set`.

Anything not verified as a stock symbol was left out.

## NPU

Not invented, and not copied into the fragment.

Vendor `sun60i-a733-orangepi-zero3w.dts` already has:

```
&npu {
	npu-supply = <&reg_dcdc2>;
	status = "okay";
};
```

`linux-sun60iw2-current-a733.config` has, under "NPU Drivers":

```
CONFIG_AW_NNA_VIP=m
CONFIG_NNA_VIP2=y
# CONFIG_NPU_USER_IOMMU is not set
# CONFIG_NPU_SET_CLK_VOL is not set
# CONFIG_AW_NNA_GALCORE is not set
```

Those names are vendor-local. Leave them in the vendor config. Do not
add a second NPU symbol and do not turn the node off.

## Wi-Fi / Bluetooth

Not invented, and not copied into the fragment.

The same board dts enables `&rfkill` (`allwinner,sunxi-rfkill`,
`status = "okay"`):

- WLAN `wlan_regon` = `<&r_pio PM 1 GPIO_ACTIVE_HIGH>`
- WLAN `wlan_hostwake` = `<&r_pio PM 0 GPIO_ACTIVE_HIGH>`
- WLAN rails `axp8191-bldo5`, `axp8191-cldo1`
- BT `bt_rst_n` = `<&r_pio PM 2 GPIO_ACTIVE_LOW>`
- `&btlpm`: `bt_wake` PM3, `bt_hostwake` PM4

`orangepizero3w.conf` sets `MODULES="aic8800_fdrv aic8800_btlpm"`.
The A733 kernel config sets `CONFIG_AIC_WLAN_SUPPORT=y`,
`CONFIG_AIC_INTF_SDIO=y`, `CONFIG_AIC8800_WLAN_SUPPORT=m`,
`CONFIG_AIC8800_BTLPM_SUPPORT=m`. Out of tree. Do not rename them to a
mainline mac80211 driver and do not redefine `&rfkill`.

## Pinctrl

ESP32 reset, ESP32 boot, MagStack present, and dock detect are not
given Allwinner pins. No `gpio-hog`, no `<&pio ...>`. The lines are
named in `hardware/pin-contract.json`. The carrier node uses
`thox,logical-bus` strings (`UART-carrier-1`, `I2C-carrier`,
`USB-gadget`) only.

`CONFIG_SERIAL_DEV_BUS=y` and `CONFIG_SERIAL_DEV_CTRL_TTYPORT=y` are
mainline serdev (the vendor A733 config has
`# CONFIG_SERIAL_DEV_BUS is not set`). Turning the bus on does not
attach a carrier UART. There is no serdev child until the pin contract
names a real controller.

## GPU

The SoC GPU is an Imagination PowerVR BXM-4-64. The vendor config sets
`CONFIG_AW_GPU_TYPE="bxm"` and `CONFIG_DRM=y`. The closed driver
(`pvrsrvkm`, not in this tree) is known to deadlock a live compositor.

This fragment does not enable a desktop GPU stack. It does not unset
`CONFIG_DRM`: that flag is the sunxi display controller, not PowerVR,
and clearing it is not required to stay headless. It does set
`CONFIG_LOGO=n` (already unset in the A733 config). The image does not
start a compositor and does not install the vendor `img-bxm` X server.
Console / server only.

## Mainline is not the boot path

Mainline `sun60i-a733` is early (Cubie A7S series: UART, SD, GIC).
Do not boot this image on mainline. Boot vendor 6.6.98.

## What the fragment does change

- `CONFIG_LOCALVERSION="-thoxos"` (vendor value is `""`).
- `CONFIG_OF_OVERLAY=y` and `CONFIG_OF_CONFIGFS=y` (vendor has
  `# CONFIG_OF_OVERLAY is not set`). `CONFIGFS_FS` is already `y`.
- `CONFIG_WIREGUARD=m` (vendor has `# CONFIG_WIREGUARD is not set`).
- `CONFIG_INET_ESP=m` overrides vendor `CONFIG_INET_ESP=y`. ESP becomes
  a module.
- `CONFIG_MD=y`, `CONFIG_BLK_DEV_DM=y`, `CONFIG_DM_CRYPT=y`,
  `CONFIG_DM_VERITY=y`. Device mapper is off in the vendor config.
- `CONFIG_TMPFS_POSIX_ACL=y` (vendor has it unset; `CONFIG_TMPFS=y`).
- `CONFIG_PANIC_TIMEOUT=5` (vendor is `0`).
- `CONFIG_USB_ACM=m` is the host CDC-ACM driver (`cdc-acm`). The vendor
  A733 config has `CONFIG_USB_ACM=y`. Gadget functions `usb_f_acm` and
  `usb_f_rndis` are `CONFIG_USB_F_ACM` / `CONFIG_USB_F_RNDIS`, already
  `=y` because `CONFIG_USB_CONFIGFS` and `CONFIG_USB_CONFIGFS_ACM` /
  `CONFIG_USB_CONFIGFS_RNDIS` are `y`. This fragment keeps the configfs
  options `=y`. Do not expect `usb_f_acm.ko` or `usb_f_rndis.ko` unless
  `olddefconfig` builds those functions as modules.

`CONFIG_SQUASHFS`, `CONFIG_SQUASHFS_XZ`, `CONFIG_OVERLAY_FS`,
`CONFIG_AUTOFS_FS`, `CONFIG_CGROUP_BPF`, `CONFIG_BPF_SYSCALL`,
`CONFIG_IKCONFIG`, `CONFIG_IKCONFIG_PROC`, and `CONFIG_MAGIC_SYSRQ`
are already `y` in the vendor A733 config. They are repeated so the
fragment still states the requirement if the base config moves.
