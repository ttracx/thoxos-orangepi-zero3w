# Bring-up — Orange Pi Zero 3W carriers

Copyright 2026 THOX.ai LLC

SPDX-License-Identifier: Apache-2.0

Bench order for ThoxMini and ThoxClip. Stop on a failed step. Later steps assume the earlier ones passed. Nets are the logical names in `pin-contract.json`. Confidence is `contract`, not silkscreen. Pin numbers are not in this checklist because they are not known. Where a step says to look at the module, write the observed silkscreen into a lab note. Do not copy that note back into this revision as if it were the contract.

Enclosure stays off through the thermal step. The old 13.8 mm height target does not apply.

## 1. Incoming

Confirm the board is an Orange Pi Zero 3W, not a different Zero.

- ThoxMini preferred 8 GB, floor 4 GB. ThoxClip preferred 4 GB, floor 2 GB.
- Reject the 1 GB LPDDR4/4X SKU. Do not boot it "just to see."
- eMMC and UFS footprints unstuffed, unless a written deviation names the part and admits it is not the 1.0.0 boot device.
- PCIe FPC empty.
- Qi coil, if a Mini mechanical sample has one, has no copper into the 5 V rail.
- Magnets, if already fitted, have no pole map in this repo. Do not add one. Polarity rule remains: opposes the phone-side stack, frozen only by a marked prototype.

Pass: SKU and stuff options match the BOM row you think you are building.

## 2. Power only

No enclosure. No radio test. No SD card required for this step.

Apply 5 V through the module USB 2.0 Type-C power port (`USB_C_5V`). The source must be able to supply 3 A. A current-limited bench supply is allowed only at 5.0 V into that same port. Do not negotiate USB-PD above 5 V. This contract has no PD profile.

Leave disconnected: Qi, MagStack mate, phone dock, OTG cable, HDMI, DSI, CSI, fan, PCIe.

Do not feed the unnumbered power through-holes. This contract does not claim they are the 5 V net.

Pass: the module takes 5 V and does not brown out or overheat at idle on the bench. Fail the board if it only comes up by back-feeding the OTG port or the Qi study.

## 3. Module debug UART

Label on the bench: module debug UART. Net `MODULE_UART_DEBUG`.

- Through-holes on the module.
- Baud 115200.
- Pins are not numbered in this contract. Identify TX, RX, and ground from the physical module. Do not use a Raspberry Pi debug header, a BCM number, or an Allwinner port.pin guess.
- Working framing until a vendor banner says otherwise: 8N1, no flow control.

Pass: characters from the module ROM or bootloader at 115200. If the holes cannot be identified without guessing, stop and record the silkscreen. Do not continue on a guessed pinout.

## 4. Vendor image on microSD

Write a vendor Orange Pi image to microSD (up to 128 GB) using the vendor's own imaging method. Boot from `MODULE_SD` on `USB_C_5V`.

Do not rewrite the partition table. Do not flash boot0. Do not "repair" the image by replacing the vendor loader.

Pass: the vendor image reaches a shell on `MODULE_UART_DEBUG`.

## 5. ThoxOS overlay

Apply the ThoxOS overlay onto the partitions the running vendor image already has. This document does not list partition names or byte offsets. Those belong to the image you just booted.

If the overlay procedure requires repartitioning or rewriting boot0, stop. That procedure is outside 1.0.0.

Pass: the overlay userspace is up on the same SD layout, still with no display server.

## 6. Antenna, before any radio

Fit the IPEX pigtail on `IPEX_ANT` before any radio test. That covers module Wi-Fi 6, module BT 5.4, and on ThoxMini the ESP32-C6 as well.

- Mini: route the module pigtail toward where the enclosure wall will be. The wall is not fitted yet.
- Clip: this pigtail is the clip link. There is no second radio to fall back on.
- Press cites Cdtech 20800D8-00. The kernel driver name is UNKNOWN. Pass is the name the booted kernel actually registers, written into the lab note. Do not fill this file in with a guess if the interface is missing.

Fail the radio step if the IPEX is open. Do not "briefly" associate.

## 7. Thermals, still unenclosed

Do not enclose before this step. Enclosure height is not a known input; do not build a 13.8 mm shell to make the test faster.

Run the load you care about in open air. For ThoxMini, populate the module 2-pin fan (`MODULE_FAN`) before a sustained NPU run. That header is not a 40-pin `PWM_FAN`. How the module controls the fan is not documented here; confirm the vendor fan interface on the running image rather than exporting a random PWM chip.

ThoxClip's A76 offline or cap is a userspace policy applied after boot. It is not a substitute for the open-air measurement, and it is not a fuse you install in this step.

Pass: temperatures are recorded unenclosed, with the fan state written down (empty header vs populated). Only then may a mechanical shell be designed. Height still comes from a measured stack-up, not from this file.

## 8. ThoxMini coprocessor

Skip this step on ThoxClip.

The ESP32-C6 may be held in reset until `thoxos-carrier.service` drives `GPIO_ESP_RST` high. Before that service exists, EN must already be held low by the carrier (the 40-pin pin is high-Z at power-on; a floating EN is a fail). Product boot leaves `GPIO_ESP_BOOT` at the run level. Do not enter download mode on a unit you are trying to boot.

If the ESP32-C6 is absent, or the service does not run: Mini still boots. Mesh radio degrades (Thread, Zigbee, Matter down). Do not block boot. Do not hold the boot loader waiting for UART traffic from the coprocessor. Silence on `UART_ESP_RX` is expected while reset is held.

MagLink is the same rule. A missing 24C02 or INA219 degrades identity or current sense and does not fail the boot step. Probe `I2C_MAG_SDA` / `I2C_MAG_SCL` only after userspace is up. Addresses are 7-bit 0x50 and 0x40.

`GPIO_MAG_PRESENT` is recorded, not policed. Active level is not frozen.

## 9. ThoxClip dock and gadget

Skip this step on ThoxMini.

Boot undocked first and confirm step 5. Then dock to a host phone.

- Observe `GPIO_DOCK_DET`. Write down the level. Do not "fix" it in hardware during the first pass.
- Bind USB gadget functions ACM and RNDIS on `USB_C_OTG`.
- Confirm the phone enumerates those functions.
- Leave DP Alt unbound. Do not start a display server.
- Remove the dock and confirm the gadget unbinds and the Clip stays up on `USB_C_5V`.

Pass: undocked boot, docked ACM + RNDIS, undocked still up. Fail if the Clip only powers from the phone.

## Do not

- Do not rewrite the partition table.
- Do not start X11 or Wayland.
- Do not flash boot0.
- Do not boot from Qi, from a MagStack mate, from OTG VBUS, or from the phone dock.
- Do not negotiate USB-PD above 5 V.
- Do not design, buy, or bring up the 1 GB LPDDR4/4X SKU.
- Do not invent BCM numbers, Allwinner port.pin numbers, or a 40-pin index. Contract nets are names, not locations.
- Do not invent a magnet pole map. Polarity opposes the phone-side stack; freeze it with a marked prototype.
- Do not claim an enclosure height. The old 13.8 mm target does not apply to this module until a stack-up is measured.
- Do not enclose before the thermal step.
- Do not transmit with the IPEX unmated.
- Do not treat a floating ESP32-C6 EN as held in reset.
- Do not block Mini boot on a missing ESP32-C6, a missing MagLink device, or a missing `thoxos-carrier.service`.
- Do not put an ESP32, MagLink, or a Qi coil on a ThoxClip.
- Do not enforce the Clip A76 policy with a hardware fuse or a strap.
- Do not stuff eMMC, UFS, or a PCIe device as part of first boot.
- Do not alias `MODULE_FAN` as `PWM_FAN`.
