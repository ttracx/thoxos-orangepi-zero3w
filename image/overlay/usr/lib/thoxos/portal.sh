#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# On-device portal stub. The full portal is still planned in thoxos-core.
# This process must not bind a port. Every 30 seconds it rewrites
# /run/thoxos/status.json so the unit stays up and a later reader can see it.

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

json_sane() {
  js_in=$1
  js_out=""
  js_ch=""
  while [ -n "$js_in" ]; do
    js_ch=${js_in%"${js_in#?}"}
    js_in=${js_in#?}
    case "$js_ch" in
      [A-Za-z0-9._-]*)
        js_out="${js_out}${js_ch}"
        ;;
    esac
  done
  printf '%s' "$js_out"
}

while true; do
  mkdir -p /run/thoxos
  sku=$(kv_get /etc/thoxos/sku.env SKU || true)
  sku=$(json_sane "$sku" || true)
  image_id=$(kv_get /etc/thoxos-release IMAGE_ID || true)
  image_id=$(json_sane "$image_id" || true)
  if [ -z "$image_id" ]; then
    image_id="thoxos-opi3w-1.0.0"
  fi
  uptime_s="0"
  if [ -r /proc/uptime ]; then
    uptime_line=""
    IFS= read -r uptime_line < /proc/uptime || uptime_line=""
    uptime_s=${uptime_line%% *}
  fi
  case "$uptime_s" in
    ""|*[!0-9.]*)
      uptime_s="0"
      ;;
  esac
  tmp="/run/thoxos/status.json.tmp"
  printf '%s\n' "{\"sku\":\"${sku}\",\"image_id\":\"${image_id}\",\"uptime\":\"${uptime_s}\",\"headless\":true}" > "$tmp"
  mv -f "$tmp" /run/thoxos/status.json
  sleep 30
done
