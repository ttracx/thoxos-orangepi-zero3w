# Handoff

THOX-NODE: sadie-grok
THOX-SEAT: foundry
THOX-IDENTITY: sadie
THOX-AGENT: thox-sadie-grok
THOX-MSG: thoxos-opi3w-1.0.0 dispatch
THOX-VERIFY: source-tree-only

Subject: ThoxOS Orange Pi Zero 3W image | node:sadie-grok

## Dispatch

| Team | Owns | Does not own |
| --- | --- | --- |
| Kernel | `kernel/` | blobs, silkscreen pin numbers |
| Bootloader | `boot/` | boot0 sectors, GPT rewrite |
| Firmware | `firmware/` | redistribution of vendor blobs |
| Hardware | `hardware/` | enclosure height, magnet polarity map |
| Image | `image/` | flashing, apt at first boot |
| Foundry | `build/`, this desk | claiming a card was written |

## Decision

Base stamp is `Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98`.
Headless. Single-slot vendor layout for 1.0.0. RAUC compatible string
`thoxos-opi3w` is reserved for the measured production GPT.

## Open

1. Confirm vendor defconfig name and `bootcmd` symbol on a serial console.
2. Measure `sfdisk -d` before any partition work.
3. Freeze 40-pin nets against the Orange Pi pin figure before PCB.
4. Install vendor NPU userspace out of band, then expect `thoxos-npu-probe` to leave exit 4.
