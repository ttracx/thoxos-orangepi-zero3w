#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
# Overlay a ThoxOS SKU onto an unpacked Orange Pi Zero 3W server image.
# Does not download the vendor archive. Does not rewrite partitions.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SKU=thoxmini
BASE=
OUT=
CHECK=0
STAMP_FILE="Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98"

usage() {
  echo "usage: thoxos-image.sh --check" >&2
  echo "       thoxos-image.sh --sku thoxmini|thoxclip --base IMAGE.img --out OUT.img" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --sku) SKU=${2:?}; shift ;;
    --base) BASE=${2:?}; shift ;;
    --out) OUT=${2:?}; shift ;;
    --partition-rewrite)
      echo "thoxos-image: --partition-rewrite is unsupported in 1.0.0" >&2
      exit 2
      ;;
    -h|--help) usage ;;
    *) echo "thoxos-image: unknown argument $1" >&2; usage ;;
  esac
  shift
done

case "$SKU" in
  thoxmini|thoxclip) ;;
  *) echo "thoxos-image: sku must be thoxmini or thoxclip" >&2; exit 2 ;;
esac

if [ ! -f "$ROOT/image/validate.py" ]; then
  echo "thoxos-image: image/validate.py missing" >&2
  exit 1
fi

python3 "$ROOT/image/validate.py" "$ROOT"

need_file() {
  if [ ! -f "$ROOT/$1" ]; then
    echo "thoxos-image: missing $1" >&2
    exit 1
  fi
}

need_file kernel/thoxos_opi_zero3w.fragment
need_file kernel/dts/sun60i-a733-thoxmini-opi3w.dts
need_file kernel/dts/sun60i-a733-thoxclip-opi3w.dts
need_file boot/boot.cmd
need_file boot/env/thoxos.env.txt
need_file boot/rauc/system.conf
need_file firmware/manifest.yaml
need_file firmware/npu/thoxos-npu-probe
need_file hardware/pin-contract.json
need_file image/overlay/etc/thoxos-release
need_file image/overlay/usr/lib/thoxos/firstboot.sh

echo "thoxos-image: tree ok sku=$SKU image=thoxos-opi3w-1.0.0"

if [ "$CHECK" -eq 1 ]; then
  exit 0
fi

if [ -z "$BASE" ] || [ -z "$OUT" ]; then
  usage
fi

case "$BASE" in
  *desktop*|*xfce*)
    echo "thoxos-image: refusing desktop base $BASE" >&2
    exit 2
    ;;
esac

case "$BASE" in
  *5.15.147*)
    echo "thoxos-image: refusing kernel 5.15.147 base (pin is 6.6.98)" >&2
    exit 2
    ;;
esac

case "$BASE" in
  *"$STAMP_FILE"*) ;;
  *resolute*server*linux6.6.98*)
    echo "thoxos-image: alternate resolute server base, not the stamp" >&2
    ;;
  *)
    echo "thoxos-image: base filename is not the jammy server 6.6.98 stamp" >&2
    echo "thoxos-image: expected name containing $STAMP_FILE" >&2
    exit 2
    ;;
esac

if [ ! -f "$BASE" ]; then
  echo "thoxos-image: base image not found: $BASE" >&2
  exit 1
fi

command -v python3 >/dev/null
cp -a -- "$BASE" "$OUT"

MNT=$(mktemp -d)
cleanup() {
  if mountpoint -q "$MNT" 2>/dev/null; then
    umount "$MNT" || true
  fi
  rmdir "$MNT" || true
}
trap cleanup EXIT

# Vendor jammy images are a single ext4 filesystem. Try the whole image,
# then the first partition offset if the kernel asks for one.
if ! mount -o loop,rw "$OUT" "$MNT" 2>/dev/null; then
  OFF=$(sfdisk -J "$OUT" 2>/dev/null | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(1)
parts=d["partitiontable"]["partitions"]
start=int(parts[0]["start"])
sec=int(d["partitiontable"].get("sectorsize",512))
print(start*sec)
' || true)
  if [ -z "${OFF:-}" ]; then
    echo "thoxos-image: could not mount $OUT and no partition offset was readable" >&2
    echo "thoxos-image: leave the vendor table intact and mount it on the bench" >&2
    exit 1
  fi
  mount -o loop,rw,offset="$OFF" "$OUT" "$MNT"
fi

copy_tree() {
  src=$1
  dest=$2
  mkdir -p "$dest"
  cp -a "$src"/. "$dest"/
}

copy_tree "$ROOT/image/overlay" "$MNT"
printf 'SKU=%s\n' "$SKU" > "$MNT/etc/thoxos/sku.env"

rel=$MNT/etc/thoxos-release
if [ -f "$rel" ]; then
  tmp=$(mktemp)
  sed "s/^SKU=.*/SKU=$SKU/" "$rel" > "$tmp"
  mv "$tmp" "$rel"
fi

mkdir -p "$MNT/boot"
cp "$ROOT/boot/boot.cmd" "$MNT/boot/boot.cmd"
cp "$ROOT/boot/env/thoxos.env.txt" "$MNT/boot/thoxos.env.txt"
if command -v mkimage >/dev/null 2>&1; then
  mkimage -C none -A arm64 -T script -d "$ROOT/boot/boot.cmd" "$MNT/boot/boot.scr"
else
  echo "thoxos-image: mkimage not installed; left boot.cmd without boot.scr" >&2
fi

# Enablement is a wants symlink. systemctl --root is used when present.
if command -v systemctl >/dev/null 2>&1; then
  systemctl --root="$MNT" enable thoxos-firstboot.service thoxos-portal.service \
    thoxos-health.service thoxos-carrier.service thoxos-npu-probe.service \
    >/dev/null 2>&1 || true
  if [ "$SKU" = "thoxmini" ]; then
    systemctl --root="$MNT" enable thoxos-mesh.service >/dev/null 2>&1 || true
  else
    systemctl --root="$MNT" enable thoxos-gadget.service >/dev/null 2>&1 || true
  fi
fi

echo "thoxos-image: wrote $OUT sku=$SKU"
echo "thoxos-image: bootloader sectors were not moved"
