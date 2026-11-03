#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# USB gadget stub. Acts only when SKU=thoxclip and configfs usb_gadget exists.
# functions land after the vendor USB gadget DTS is confirmed.
# 1.0.0 does not configure a gadget function.

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

sku=$(kv_get /etc/thoxos/sku.env SKU || true)

if [ "$sku" != "thoxclip" ]; then
  echo "gadget skipped sku=$sku"
  exit 0
fi

if [ ! -d /sys/kernel/config/usb_gadget ]; then
  echo "gadget skipped configfs usb_gadget absent"
  exit 0
fi

mkdir -p /run/thoxos
printf '%s\n' "state=armed-not-configured" > /run/thoxos/gadget
exit 0
