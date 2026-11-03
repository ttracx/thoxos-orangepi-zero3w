#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# First boot for the ThoxOS vendor-Ubuntu overlay.
# No network. No apt. No systemd drop-in.
# Machine-id is never rewritten. A stamp records whether one was already present.

set -eu
umask 022

kv_get() {
  kv_file=$1
  kv_key=$2
  kv_out=""
  kv_line=""
  if [ -f "$kv_file" ]; then
    while IFS= read -r kv_line || [ -n "$kv_line" ]; do
      case "$kv_line" in
        "#"*)
          continue
          ;;
        "${kv_key}"=*)
          kv_out=${kv_line#${kv_key}=}
          ;;
      esac
    done < "$kv_file"
  fi
  kv_cr=$(printf '\r')
  kv_out=${kv_out%"$kv_cr"}
  while [ -n "$kv_out" ] && [ "$kv_out" != "${kv_out# }" ]; do
    kv_out=${kv_out# }
  done
  while [ -n "$kv_out" ] && [ "$kv_out" != "${kv_out% }" ]; do
    kv_out=${kv_out% }
  done
  case "$kv_out" in
    \"*\")
      kv_out=${kv_out#\"}
      kv_out=${kv_out%\"}
      ;;
  esac
  printf '%s' "$kv_out"
}

mkdir -p /var/lib/thoxos

if [ -e /etc/machine-id ]; then
  touch /var/lib/thoxos/machine-id-kept
else
  touch /var/lib/thoxos/machine-id-absent
fi

sku=$(kv_get /etc/thoxos/sku.env SKU || true)

host_now=""
if [ -f /etc/hostname ]; then
  IFS= read -r host_now < /etc/hostname || host_now=""
  cr=$(printf '\r')
  host_now=${host_now%"$cr"}
fi

case "$host_now" in
  ""|orangepi|orangepizero3w|localhost)
    if [ -n "$sku" ]; then
      printf '%s\n' "$sku" > /etc/hostname
    fi
    ;;
esac

touch /var/lib/thoxos/firstboot-done
echo "THOXOS firstboot sku=$sku"
