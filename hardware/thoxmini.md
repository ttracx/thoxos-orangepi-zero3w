# ThoxMini — MagMesh node

Copyright 2026 THOX.ai LLC

SPDX-License-Identifier: Apache-2.0

ThoxMini is the Orange Pi Zero 3W plus a carrier. The module is the compute element. The carrier adds the ThoxRoute coprocessor, MagLink, MagStack presence, the magnet array, and a Qi study that is not a supply. Logical nets are in `pin-contract.json`. Confidence is `contract`, not silkscreen. No BCM numbers. No Allwinner port.pin numbers. No 40-pin index.

Preferred RAM is 8 GB LPDDR5. Floor is 4 GB. The 1 GB LPDDR4/4X SKU is rejected. Boot media is microSD. eMMC and UFS stay unstuffed.

## Interface list

| Net | Role in 1.0.0 |
| --- | --- |
| `USB_C_5V` | Only boot power. Module USB 2.0 Type-C, 5 V / 3 A. |
| `USB_C_OTG` | Present. Not the boot inlet. No gadget requirement on Mini. DP Alt unused. |
| `HDMI_MINI`, `MIPI_DSI` | Present on the module. Display server off. Optional DSI panel is not driven. |
| `MIPI_CSI0`, `MIPI_CSI1` | Unused. |
| `IPEX_ANT` | Module Wi-Fi 6 + BT 5.4. Pigtail to the enclosure wall. Driver name UNKNOWN. |
| `MODULE_FAN` | Module 2-pin header, not a 40-pin PWM. Fit before sustained NPU. |
| `PCIE_FPC` | Unpopulated. |
| `MODULE_UART_DEBUG` | Bench console, 115200, pins not numbered. |
| `MODULE_SD` | Boot disk. Do not rewrite the partition table. |
| `UART_ESP_TX`, `UART_ESP_RX` | Host link to the ESP32-C6. 3.3 V. Baud not frozen. |
| `GPIO_ESP_RST` | Holds ESP32-C6 EN low until `thoxos-carrier.service`. |
| `GPIO_ESP_BOOT` | Run strap for product boot. Download only on the bench. |
| `I2C_MAG_SCL`, `I2C_MAG_SDA` | MagLink. 24C02 at 0x50, INA219 at 0x40. |
| `GPIO_MAG_PRESENT` | MagStack presence. Level not frozen. Does not gate boot. |
| `QI_COIL_STUDY` | Mechanical study. Open circuit to 5 V. |

Module SPI and 40-pin PWM have no Mini device. Do not alias the fan as `PWM_FAN`.

## ESP32-C6 (ThoxRoute)

The coprocessor is an ESP32-C6 module: Wi-Fi 6, BLE 5, and 802.15.4 for Thread, Zigbee, and Matter. The exact Espressif module SKU is not frozen. Buy only a module that exposes chip-enable (EN / CHIP_PU), the download strap, and a host UART. Its RF antenna is the one that module integrates. It is not the compute-module IPEX. A second pigtail is an open procurement item only if that SKU has no antenna of its own.

Chip-side straps, which still have to be checked on the chosen module pinout:

- EN is active-high. High runs the chip. Low holds it off. EN must not float.
- Download strap is chip GPIO9. Default high is flash boot. Low at the moment EN rises is download mode.
- Chip GPIO8 must not be held low at the same time as GPIO9. The carrier does not strap GPIO8.

`GPIO_ESP_RST` is the carrier net into EN. The Orange Pi 40-pin is high-Z until software claims it, so a pull-down on EN has to win during that window. `thoxos-carrier.service` is what drives EN high. The resistor value is not frozen. Do not treat a floating GPIO as "held in reset."

`GPIO_ESP_BOOT` must already be at the run level before EN is released. Product firmware never asserts download. A bench download is: drive `GPIO_ESP_BOOT` low, then pulse `GPIO_ESP_RST`.

`UART_ESP_TX` is module-out into the coprocessor. `UART_ESP_RX` is module-in. No RTS/CTS nets. Level is 3.3 V, not 5 V. Baud and framing are not frozen in hardware; do not assume the debug console's 115200.

The ESP32-C6 3.3 V source is not selected. It may be a carrier regulator from the module 5 V port, or a module 3.3 V pin identified at layout from the physical board. This contract does not name that pin. Do not back-power the Zero 3W from the coprocessor supply.

## MagLink

One I2C bus, two devices, 7-bit addresses:

- 24C02 ID EEPROM at 0x50. Capacity is 256 bytes. Address pins strapped so the address is 0x50, not a floating alternate.
- INA219 at 0x40. Address pins strapped for 0x40. It measures MagLink current when a shunt is fitted. The shunt value is not frozen. The part is not an input fuse and is not in the boot path.

Carrier pull-ups to 3.3 V on `I2C_MAG_SCL` and `I2C_MAG_SDA`. Value not frozen. Do not depend on undocumented pull-ups inside the Zero 3W. Bus rate not frozen.

If the EEPROM or the INA219 is missing, identity or current sense degrades. The node still boots.

## MagStack presence and magnets

`GPIO_MAG_PRESENT` tells software that a stack mate is mechanically present. The active level is an open item. Read it on the first marked prototype and record it. Do not guess, and do not refuse to boot when the line is the other way.

The N52 array is mechanical. Quantity is TBD. Polarity rule: it opposes the phone-side stack. Freeze that with a marked prototype. Do not invent a pole map. The array does not carry power and does not carry MagLink.

## Antenna

Attach the module IPEX pigtail and route it to the enclosure wall before any radio test. That includes the module Wi-Fi 6, the module BT 5.4, and the ESP32-C6. Press cites the module radio as Cdtech 20800D8-00. The driver name is UNKNOWN. A test passes when the booted kernel names the interface, not when it matches a string written here.

## Power

Primary power remains USB-C 5 V / 3 A on `USB_C_5V`. The Qi coil is a mechanical and power study, not a boot source. Leave it open-circuit to the 5 V rail and to PMIC outputs. A MagStack mate must not feed the node. There is no USB-PD profile above 5 V.

## Boot dependencies

Order that hardware must allow, which is also the software order:

1. 5 V on the module power Type-C.
2. microSD with the vendor image. Partition table left as the vendor wrote it. boot0 not rewritten.
3. ThoxOS overlay on that existing layout.
4. Userspace, including the case where `thoxos-carrier.service` is not installed yet.
5. Only then may `thoxos-carrier.service` release `GPIO_ESP_RST`.
6. MagLink probe and mesh traffic are after that release. They are not required to reach userspace.

The fan, panel, cameras, PCIe, HDMI, and DP Alt are not in this list.

## If the ESP32-C6 is absent

Mini still boots. The mesh radio degrades: Thread, Zigbee, and Matter are down because they live on the coprocessor, not on the compute-module radio. The module Wi-Fi 6 + BT 5.4 can still come up once the IPEX is fitted, and its driver is still UNKNOWN until the kernel says otherwise. Do not block boot. Do not kernel-panic. Do not drop to an installer because the UART is silent. Silence is the expected state while EN is held low, and it is also the expected state when the module is not stuffed.

The same rule applies when the part is stuffed but `thoxos-carrier.service` never releases reset. Host boot succeeds. ThoxRoute stays down until the service runs.

## Not in 1.0.0

- Display server, X11, Wayland, HDMI use, DP Alt use, MIPI-DSI scan-out
- MIPI CSI
- PCIe endpoint
- Stuffed eMMC or UFS
- Qi as a supply
- A 40-pin PWM fan (`MODULE_FAN` is the module header)
- Boot from anything except `USB_C_5V` plus microSD
