# ThoxClip — clip companion

Copyright 2026 THOX.ai LLC

SPDX-License-Identifier: Apache-2.0

ThoxClip uses the same Orange Pi Zero 3W as ThoxMini and a smaller carrier. There is no ESP32-C6. The clip link is the module's own Wi-Fi 6 + BT 5.4. Logical nets are in `pin-contract.json`. The only carrier net on the 40-pin is `GPIO_DOCK_DET`. Confidence is `contract`, not silkscreen. No BCM numbers. No Allwinner port.pin numbers. No 40-pin index.

The board in use is the same Orange Pi Zero 3W 12 GB LPDDR5 as ThoxMini. Class floor remains 2 GB. The 1 GB LPDDR4/4X SKU is rejected. Boot media is microSD. eMMC and UFS stay unstuffed.

## Interface list

| Net | Role in 1.0.0 |
| --- | --- |
| `USB_C_5V` | Only boot power. Module USB 2.0 Type-C, 5 V / 3 A. Not the phone dock. |
| `USB_C_OTG` | USB gadget toward a host phone when docked. ACM + RNDIS. DP Alt unused. |
| `GPIO_DOCK_DET` | Dock present. Level not frozen. Does not gate boot. |
| `IPEX_ANT` | Clip link antenna for module Wi-Fi 6 + BT 5.4. Driver name UNKNOWN. |
| `HDMI_MINI`, `MIPI_DSI` | On the module. Not driven. No Clip panel. |
| `MIPI_CSI0`, `MIPI_CSI1` | Unused. |
| `MODULE_FAN` | Optional module 2-pin header. Not the low-power policy. |
| `PCIE_FPC` | Unpopulated. |
| `MODULE_UART_DEBUG` | Bench console, 115200, pins not numbered. |
| `MODULE_SD` | Boot disk. Do not rewrite the partition table. |

## Dock behavior

Undocked is a normal powered state. The Clip boots from `USB_C_5V` and microSD with the dock contact in either level. `GPIO_DOCK_DET` is an input from a mechanical switch or a hall device; which one is not frozen. The active level is not frozen. Record both from the first marked prototype. Do not hard-code a guess, and do not refuse to finish boot while the level is unknown.

When the contact says docked, userspace may attach the phone on `USB_C_OTG`. When it says undocked, userspace drops the gadget. The phone is not the boot supply in 1.0.0. Do not OR dock VBUS into `USB_C_5V`. A later revision would have to say so explicitly.

The smaller magnet clip holds the phone. Quantity is TBD. Polarity rule, same as Mini: it opposes the phone-side stack. Freeze that with a marked prototype. Do not invent a pole map. The clip magnet is not the Mini N52 array and it does not carry MagLink, because MagLink is not on this SKU.

## Gadget mode

On dock, the module is the USB device and the phone is the host, on the USB 3.1 Type-C OTG port. Functions in 1.0.0 are ACM and RNDIS. No other gadget functions are part of this contract.

DisplayPort Alt Mode 1.4 is electrically available on that same port and can do 4K60 as a module fact. ThoxOS 1.0.0 still does not start a display server, on the dock path or on Mini HDMI, because of the PowerVR compositor deadlock risk. Do not start X11 or Wayland to "prove" the dock. Dual independent display remains a silicon fact, not a software path.

DP Alt being wired is not permission to enumerate a display gadget. Leave that unbound.

## Clip link

With the IPEX pigtail fitted, module Wi-Fi 6 and BT 5.4 are the link to the rest of the system. There is no second radio. Press cites Cdtech 20800D8-00. The kernel driver name is UNKNOWN. Do not test the radio with the IPEX open. Failure of the radio degrades the clip link. It does not stop boot, and it must not be papered over by adding an ESP32 to this SKU.

## Power policy

Lower power is userspace. After boot, policy may offline the Cortex-A76 cores or cap them. Both are allowed. The choice and the cap value are not hardware. Do not implement this with a fuse, a strap, a removed core, or a PMIC bit documented outside the module vendor's own tree. The board must power up with the cores available so the vendor image can boot. Policy runs only once userspace is up.

The 6× Cortex-A55, the E902, and the NPU are still present. This contract does not disable them in copper. `MODULE_FAN` may be left unpopulated on a Clip that never runs a sustained NPU load. Leaving it off is not the power policy. An enclosed Clip still needs the open-air thermal pass in `bringup.md` before the shell goes on.

Boot current still has to be provisioned at 5 V / 3 A. The low-power policy is not a reason to feed the board from a weak charger or from the phone.

## Boot dependencies

1. 5 V on the module power Type-C. Dock state ignored.
2. microSD with the vendor image. Partition table unchanged. boot0 not rewritten.
3. ThoxOS overlay on that layout.
4. Userspace. Radio and dock are optional from this step forward.
5. IPEX fitted before any clip-link test.
6. If `GPIO_DOCK_DET` reports docked, bind ACM + RNDIS on `USB_C_OTG`. If not, stay undocked. Neither outcome gates step 4.

HDMI, MIPI-DSI, DP Alt, MIPI CSI, PCIe, and the fan are not boot dependencies.

## Intentionally absent

Do not stuff these on a Clip carrier, and do not port the Mini nets onto the Clip 40-pin "for later":

- ESP32-C6 and the ThoxRoute role
- Thread, Zigbee, and Matter coprocessor
- `UART_ESP_TX`, `UART_ESP_RX`, `GPIO_ESP_RST`, `GPIO_ESP_BOOT`
- MagLink: `I2C_MAG_SCL`, `I2C_MAG_SDA`, 24C02, INA219
- `GPIO_MAG_PRESENT` (Clip dock is `GPIO_DOCK_DET` only)
- Qi coil study
- N52 magnet array (the smaller clip magnet replaces it)
- A hardware fuse or copper strap that offlines or caps the A76 cores
- MIPI-DSI panel
- PCIe device
- Default-stuffed eMMC or UFS
- A display server

The module still has the silicon for display, camera, PCIe, NPU, and a fan header. Absent means the carrier and the 1.0.0 software do not use them, not that the SoC was depopulated.
