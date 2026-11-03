#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# Health gate the later RAUC hook calls. Does not reboot.
# Writes PASS or FAIL lines to /run/thoxos/health. Exit 0 only if every check passes.

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

mkdir -p /run/thoxos
fail=0
tmp="/run/thoxos/health.tmp"
: > "$tmp"

if [ -f /etc/thoxos-release ]; then
  printf '%s\n' "PASS thoxos-release" >> "$tmp"
else
  printf '%s\n' "FAIL thoxos-release missing" >> "$tmp"
  fail=1
fi

sku=$(kv_get /etc/thoxos/sku.env SKU || true)
case "$sku" in
  thoxmini|thoxclip)
    printf '%s\n' "PASS sku=$sku" >> "$tmp"
    ;;
  *)
    printf '%s\n' "FAIL sku=$sku" >> "$tmp"
    fail=1
    ;;
esac

if command -v systemctl >/dev/null 2>&1; then
  graphical_state=$(systemctl is-active graphical.target 2>/dev/null || true)
  if [ "$graphical_state" = "active" ]; then
    printf '%s\n' "FAIL graphical.target active" >> "$tmp"
    fail=1
  else
    printf '%s\n' "PASS graphical.target not active" >> "$tmp"
  fi
else
  printf '%s\n' "PASS graphical.target skipped" >> "$tmp"
fi

mv -f "$tmp" /run/thoxos/health

if [ "$fail" -ne 0 ]; then
  exit 1
fi
exit 0
