<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 THOX.ai LLC
-->

# Xuantie E902

The A733 integrates a Xuantie E902 RISC-V coprocessor, rated by the
vendor at up to 200 MHz. The vendor kernel reaches it through arisc /
remoteproc. The firmware that coprocessor runs is the vendor image's
firmware.

ThoxOS 1.0.0 does not replace that firmware. This directory ships no
blob, no load address, and no remoteproc script.

Do not route MagLink through the E902.
Do not route the carrier ESP32 (including the ThoxMini ESP32-C6) through
the E902. Those links stay on their own transports. The E902 is not a
substitute for either one.
