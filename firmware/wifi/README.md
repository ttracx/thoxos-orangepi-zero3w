<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 THOX.ai LLC
-->

# Wi-Fi 6 and Bluetooth 5.4

The Orange Pi Zero 3W radio is on the SoC module. Press material cites
the module as Cdtech 20800D8-00 with an IPEX antenna connector. This
tree does not confirm a schematic part number beyond that cite.
Vendor `orangepizero3w.conf` names the modules `aic8800_fdrv` and
`aic8800_btlpm` (`CONFIG_AIC8800_WLAN_SUPPORT`, `CONFIG_AIC8800_BTLPM_SUPPORT`).
That is a board-file fact, not a mainline mac80211 driver name. Confirm
the modules are loaded on a serial boot before a carrier spin. Do not
rename them.

The vendor board DTS enables `&rfkill` (`allwinner,sunxi-rfkill`), the
sunxi-wlan / sunxi-bt rfkill block. Rails named there are
`axp8191-bldo5` and `axp8191-cldo1`, both 1.8 V. GPIO properties:
`wlan_regon` on `r_pio` PM1, `wlan_hostwake` on PM0, `bt_rst_n` on PM2.

Firmware blobs, if the vendor image contains them, stay in that image.
Upstream files are only referenced at
<https://github.com/orangepi-xunlong/firmware>.
Nothing from that repository is copied here.

## Antenna

The connector is IPEX. An external antenna is required when the board
sits in a metal or carbon enclosure. Do not rely on the bare IPEX
receptacle inside those enclosures.

## Regulatory domain

Leave the regulatory domain unset in the image. Do not set a US country
code in this tree. The device ships globally. The domain is chosen when
a unit is provisioned for a ship-to region, not baked into firmware.

## Which radio is which

Bluetooth 5.4 on this module is the ThoxClip link.

ThoxMini also carries an ESP32-C6 on the carrier board for Matter,
Thread, and Zigbee. That radio is not A733 firmware and is not
described here. See the ThoxMini carrier hardware document (outside
this firmware directory). Do not point MagLink or the ESP32 at the
vendor E902 path; see [../e902/README.md](../e902/README.md).
