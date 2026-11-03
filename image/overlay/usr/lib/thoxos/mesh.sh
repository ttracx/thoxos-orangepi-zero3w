#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# Mini mesh stub. The clip class does not enable this unit.
# No WireGuard config is generated. The image contains no keys.

set -eu
umask 022
mkdir -p /run/thoxos
printf '%s\n' "state=degraded" "reason=esp32-not-in-kernel-yet" > /run/thoxos/mesh
exit 0
