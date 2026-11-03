# ThoxOS hardware — Orange Pi Zero 3W

Copyright 2026 THOX.ai LLC

SPDX-License-Identifier: Apache-2.0

Two carriers, one compute module. ThoxMini is the MagMesh node. ThoxClip is the clip companion. The compute module is the Orange Pi Zero 3W on both. ThoxOS 1.0.0 does not start a display server.

This directory is a contract, not a schematic and not a silkscreen. The official 40-pin pin-number silkscreen is not in hand. Every header assignment in `pin-contract.json` has confidence `contract`. That means a logical net name only. It is not a pin number, not a BCM number, and not an Allwinner port.pin number. Do not build a 40-pin harness from this tree. Power, ground, and pin index stay a layout hold until a later revision records the physical silkscreen under a new confidence value. This revision uses only `contract`.

`bom.csv` in this directory is under the same copyright and license. It has no prices.

## Module facts (do not retune)

SoC Allwinner A733:

- 2× Cortex-A76 up to 2.0 GHz
- 6× Cortex-A55 (maximum is not a carrier design input; public pages do not agree, so do not pick a Clip cap from a guessed A55 clock)
- Xuantie E902 up to 200 MHz
- GPU Imagination BXM-4-64 MC1
- NPU up to 3 TOPS INT8
- VPU 8Kp24 decode / 4Kp30 encode

RAM on the board in use is 12 GB LPDDR5 (listing color Zero 3W 12GB). Class floors stay ThoxMini 4 GB and ThoxClip 2 GB. The 1 GB LPDDR4/4X SKU stays rejected. Do not redesign the carriers around a smaller module.

Storage on the module: microSD up to 128 GB; optional eMMC 8/16/32/64/128 GB, default unstuffed; optional UFS 32/64/128, default unstuffed. A public Orange Pi parameter page has printed eMMC as 8/16/32 only. Keep the product list above, and do not stuff any eMMC or UFS until the module vendor confirms the footprint on the board in hand.

Wireless on the module: Wi-Fi 6 + BT 5.4 BLE, IPEX antenna. Press cites Cdtech 20800D8-00. Vendor `orangepizero3w.conf` sets `MODULES="aic8800_fdrv aic8800_btlpm"`. Confirm those modules on a serial boot before a carrier spin.

Display on the module: Mini HDMI 2.0 4K60, 4-lane MIPI-DSI, USB-C DP Alt 1.4 4K60, dual independent. ThoxOS 1.0.0 does not start a display server (PowerVR compositor deadlock risk).

Camera: 2× 4-lane MIPI CSI. Unused by both SKUs in 1.0.0.

USB: USB 3.1 Type-C OTG with DP Alt, and a separate USB 2.0 Type-C 5V/3A power port.

Expansion on the module: 40-pin header (GPIO, UART, I2C, SPI, PWM), PCIe Gen3 x1 FPC, 2-pin fan, BOOT and power through-holes. SPI and PWM on that 40-pin are module capabilities. No 1.0.0 carrier device is assigned to them. The fan is the module's own 2-pin header. Its contract name is `MODULE_FAN`. The name `PWM_FAN` is not used. If a later silkscreen shows the fan on the 40-pin, revise this contract; do not add `PWM_FAN` beside `MODULE_FAN`.

Module PCB: 65 × 32 × 1.2 mm, about 14 g. That is the bare module, not an enclosed product.

A distributor photograph of the module shows an AXP318W. Treat that as a hint, not a schematic. This contract does not document PMIC registers or intermediate rails. The carrier must not inject a second supply onto a PMIC output.

## What is module vs carrier

Orange Pi Zero 3W, both SKUs. Not designed here:

- SoC, RAM, module wireless, IPEX receptacle
- USB-C 5V/3A power port and USB-C 3.1 OTG port
- Mini HDMI, MIPI-DSI, both MIPI CSI
- microSD socket, eMMC footprint, UFS footprint
- 40-pin header, PCIe Gen3 x1 FPC, 2-pin fan header
- BOOT through-holes, power through-holes, debug UART through-holes

ThoxMini carrier adds:

- ESP32-C6 (Wi-Fi 6 / BLE 5 / 802.15.4 for Thread, Zigbee, Matter) as the ThoxRoute coprocessor, on a UART plus reset and boot straps
- MagLink I2C: ID EEPROM 24C02 at 7-bit 0x50, INA219 at 7-bit 0x40
- MagStack presence GPIO
- IPEX pigtail from the module receptacle to the enclosure wall
- N52 magnet array, mechanical only
- Qi coil as a mechanical and power study, not a supply
- optional MIPI-DSI panel, not driven in 1.0.0
- PCIe FPC left unpopulated

ThoxClip carrier adds:

- dock-detect GPIO
- USB gadget use of the module OTG port (ACM + RNDIS) when docked to a host phone
- a smaller magnet clip, mechanical only
- nothing else on the 40-pin

ThoxClip does not add an ESP32. The clip link is the module's own Wi-Fi 6 + BT 5.4.

## Block diagram

```
ThoxMini (MagMesh node)

  phone-side stack
        |
        |  N52 array: polarity opposes that stack
        |  pole map is not drawn; freeze a marked prototype
        |  MagLink: I2C_MAG_SCL / I2C_MAG_SDA
        |           24C02 @ 0x50, INA219 @ 0x40
        |  GPIO_MAG_PRESENT
        |
  +-----+------------------ carrier ----------------------+
  | ESP32-C6  ThoxRoute                                   |
  |   Wi-Fi 6 / BLE 5 / 802.15.4 (Thread, Zigbee, Matter) |
  |   UART_ESP_TX (module out) / UART_ESP_RX (module in)  |
  |   GPIO_ESP_RST held until thoxos-carrier.service      |
  |   GPIO_ESP_BOOT left at run strap                     |
  | Qi coil ---- study only; open circuit to 5 V         |
  +--------------------------+----------------------------+
                             | 40-pin: logical names only
                             | confidence: contract
                             | pin index: UNKNOWN
  +--------------------------+---- Orange Pi Zero 3W -----+
  | Allwinner A733                                        |
  |   2x Cortex-A76 up to 2.0 GHz, 6x Cortex-A55          |
  |   Xuantie E902 up to 200 MHz                          |
  |   GPU BXM-4-64 MC1, NPU up to 3 TOPS INT8             |
  |   VPU 8Kp24 decode / 4Kp30 encode                     |
  | LPDDR5 12 GB on the board in use, floors 4 and 2     |
  | microSD boot; eMMC unstuffed; UFS unstuffed           |
  | Wi-Fi 6 + BT 5.4 -- IPEX -- pigtail -- enclosure wall |
  |   press: Cdtech 20800D8-00; modules aic8800_fdrv / aic8800_btlpm |
  | USB-C 5V/3A power  <--- only boot source              |
  | USB-C 3.1 OTG + DP Alt 1.4     display server OFF     |
  | Mini HDMI 2.0 4K60             display server OFF     |
  | MIPI-DSI panel not driven      2x MIPI CSI unused     |
  | MODULE_FAN = module 2-pin header (not 40-pin PWM)     |
  | PCIe Gen3 x1 FPC unpopulated                          |
  | debug UART through-holes, 115200, pins not numbered   |
  +-------------------------------------------------------+
```

```
ThoxClip (clip companion)

  phone
    |  dock: GPIO_DOCK_DET (level not frozen)
    |  USB gadget ACM + RNDIS on the OTG Type-C
    |  DP Alt electrically present, display server OFF
    |  smaller magnet clip: polarity opposes the phone-side
    |  stack; pole map is not drawn
    |
  +-+---------------------- carrier ----------------------+
  |  no ESP32, no MagLink, no Qi study, no N52 array      |
  +--------------------------+----------------------------+
                             | 40-pin: GPIO_DOCK_DET only
                             | confidence: contract
  +--------------------------+---- Orange Pi Zero 3W -----+
  | same module as Mini                                     |
  | LPDDR5 preferred 4 GB, floor 2 GB, never 1 GB          |
  | Wi-Fi 6 + BT 5.4 is the clip link (IPEX fitted)        |
  | USB-C 5V/3A power  <--- only boot source               |
  | A76 offline or cap is userspace, not a hardware fuse   |
  | MODULE_FAN optional; PCIe FPC unpopulated              |
  | MIPI-DSI / HDMI / CSI / DP Alt not driven              |
  +--------------------------------------------------------+
```

## Power tree

Boot power is the module USB 2.0 Type-C at 5 V / 3 A. There is no USB-PD profile in this contract. Do not negotiate a voltage above 5 V.

```
USB-C power port, 5 V / 3 A
        |
        +---> module 5 V input
                  |
                  +---> Zero 3W (SoC, RAM, SD, module radio)
                  |
                  +---> carrier loads
                        ESP32-C6 needs 3.3 V. The regulator,
                        or the module 3.3 V pin that feeds it,
                        is not selected. Either way the energy
                        comes from this 5 V port.
                        Do not back-power the module.

Not in the boot path, and not OR-ed into 5 V:

  Qi coil study on ThoxMini     open circuit to the 5 V rail
  MagStack mate                 does not power the node
  USB-C OTG VBUS                gadget or host later, not boot
  Phone dock on ThoxClip        data and detect, not boot power
  Any USB-PD contract above 5 V not part of 1.0.0
```

MagStack and Qi are not boot sources. A bench supply is allowed only if it is 5.0 V into the same power Type-C and can provide 3 A. The module power through-holes are not an alternate inlet in this contract. They are unnumbered, and this tree does not claim they are the 5 V net.

INA219, when its shunt is fitted, senses MagLink current. It is not an input fuse and not the boot switch. The shunt value is not frozen.

## Boot dependencies

Both SKUs boot from microSD on the vendor image layout, then a ThoxOS overlay. eMMC and UFS are unstuffed, so they are not boot devices in 1.0.0.

ThoxMini may hold the ESP32-C6 in reset until `thoxos-carrier.service` runs. If the ESP32 is absent, or the service never releases reset, the Mini still boots. The mesh radio (Thread, Zigbee, Matter) degrades. Do not block boot on the coprocessor, on the 24C02, on the INA219, or on `GPIO_MAG_PRESENT`.

ThoxClip boots the same way undocked. Dock detect and the USB gadget are after-boot behavior. The A76 power policy is userspace after boot, not a strap and not a fuse.

Neither SKU waits on HDMI, MIPI-DSI, DP Alt, MIPI CSI, PCIe, the fan, or a display server.

## Open mechanical items

- Enclosure height is not claimed. The old 13.8 mm target does not apply to this module until a stack-up is measured. Do not reuse that number on a drawing.
- Carrier outline, stack height, and total mass are not claimed. 65 × 32 × 1.2 mm and about 14 g are the module PCB only.
- Magnet count is TBD on both SKUs. Polarity rule, both SKUs: opposes the phone-side stack; freeze with a marked prototype; do not invent a pole map.
- IPEX pigtail length, cable route, and antenna keep-out are not claimed. The pigtail must be attached before any radio test. On ThoxMini it is routed to the enclosure wall. The ESP32-C6 antenna is whatever the chosen module integrates. Do not assume a second carrier IPEX. If the chosen ESP32-C6 module is an external-antenna variant, that is a separate open procurement item.
- The 40-pin pin index, 3.3 V pin, and ground pins are not in this contract.
- ESP32-C6 module land pattern is not frozen. Procurement must reject a module that does not expose EN, the download strap, and a host UART.
- Qi coil dimensions and whether a receiver circuit is ever stuffed are not frozen. The coil stays out of the 5 V net even if the mechanics are prototyped.
- Thermal stack is not measured. Do not enclose before an open-air thermal pass. Populate `MODULE_FAN` before a sustained Mini NPU run. Clip low power is not a reason to omit that measurement, and it is not implemented by leaving the fan off.

## Files

| File | What it locks |
| --- | --- |
| `pin-contract.json` | Logical nets, confidence `contract` only |
| `thoxmini.md` | MagMesh interfaces, ESP32 boot rule, degraded mesh |
| `thoxclip.md` | Dock, gadget, userspace power, what is absent |
| `bringup.md` | Bench order and the do-not list |
| `bom.csv` | Buy list, floors, and parts that stay unstuffed |
