#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# Carrier stub. Does not hold boot. Does not write sysfs GPIO.
# Pin numbers are not silkscreen-frozen, so none are used.

set -eu

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

case "$sku" in
  thoxmini)
    echo "mesh radio not probed"
    ;;
  thoxclip)
    echo "dock gpio not claimed because pin contract is not silkscreen-frozen"
    ;;
  *)
    echo "mesh radio not probed"
    ;;
esac

exit 0
