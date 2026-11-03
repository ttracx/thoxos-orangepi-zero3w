#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
"""Validate the ThoxOS Orange Pi Zero 3W image payload.

ROOT is the thoxos-opi-zero3w directory (the parent of image/).
A RAUC file is not required in this tree.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMAGE = ROOT / "image"

CLASSES = ("thoxmini", "thoxclip")
CLASS_FILES = ("class.json", "units.txt", "buildroot.config.fragment")
PORTAL_LINE = "thoxos-portal.service (enabled: multi-user.target)"
PORTAL_MARKER = " (enabled: multi-user.target)"

OVERLAY_SCRIPTS = (
    "usr/lib/thoxos/firstboot.sh",
    "usr/lib/thoxos/portal.sh",
    "usr/lib/thoxos/health.sh",
    "usr/lib/thoxos/carrier.sh",
    "usr/lib/thoxos/mesh.sh",
    "usr/lib/thoxos/gadget.sh",
    "usr/lib/thoxos/npu-probe",
)

PORTAL_UNIT = "usr/lib/systemd/system/thoxos-portal.service"


def main() -> int:
    failures: list[str] = []

    def report(ok: bool, message: str) -> None:
        print(("PASS " if ok else "FAIL ") + message)
        if not ok:
            failures.append(message)

    floors: dict[str, float] = {}

    for name in CLASSES:
        class_dir = IMAGE / "classes" / name
        report(class_dir.is_dir(), f"{name} class directory")
        for filename in CLASS_FILES:
            path = class_dir / filename
            report(path.is_file(), f"{name} has {filename}")

        class_json = class_dir / "class.json"
        data = None
        if class_json.is_file():
            try:
                data = json.loads(class_json.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                report(False, f"{name} class.json parses ({exc})")
            if isinstance(data, dict):
                class_name = data.get("name")
                floor = data.get("ram_gb_floor")
                name_ok = isinstance(class_name, str) and bool(class_name.strip())
                floor_ok = (
                    isinstance(floor, (int, float)) and not isinstance(floor, bool)
                )
                report(
                    name_ok and floor_ok,
                    f"{name} class.json has name and numeric ram_gb_floor",
                )
                if floor_ok:
                    floors[name] = float(floor)
            elif data is not None:
                report(False, f"{name} class.json has name and numeric ram_gb_floor")

        units_path = class_dir / "units.txt"
        if units_path.is_file():
            lines = []
            for raw in units_path.read_text(encoding="utf-8").splitlines():
                stripped = raw.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                lines.append(stripped)
            has_portal = any(
                line == PORTAL_LINE and PORTAL_MARKER in line for line in lines
            )
            report(has_portal, f"{name} units.txt has portal line")

            if name == "thoxmini":
                has_mesh = any("thoxos-mesh.service" in line for line in lines)
                report(
                    has_mesh and len(lines) > 1,
                    "thoxmini units contain thoxos-mesh.service and other units",
                )
            if name == "thoxclip":
                has_gadget = any("thoxos-gadget.service" in line for line in lines)
                report(has_gadget, "thoxclip units contain thoxos-gadget.service")
                mesh_line = any(
                    line.startswith("thoxos-mesh.service") for line in lines
                )
                report(
                    not mesh_line,
                    "thoxclip units do not start a thoxos-mesh.service line",
                )

    if "thoxmini" in floors and "thoxclip" in floors:
        report(
            floors["thoxmini"] >= floors["thoxclip"],
            "thoxmini ram_gb_floor >= thoxclip ram_gb_floor",
        )
    else:
        report(False, "thoxmini ram_gb_floor >= thoxclip ram_gb_floor")

    overlay = IMAGE / "overlay"
    for rel in OVERLAY_SCRIPTS:
        path = overlay / rel
        if not path.is_file():
            report(False, f"{rel} exists and starts with #!/bin/sh")
            continue
        first = path.read_text(encoding="utf-8").splitlines()[:1]
        shebang_ok = bool(first) and first[0].strip() == "#!/bin/sh"
        report(shebang_ok, f"{rel} exists and starts with #!/bin/sh")

    portal_unit = overlay / PORTAL_UNIT
    if not portal_unit.is_file():
        report(False, "portal unit contains WantedBy=multi-user.target")
    else:
        text = portal_unit.read_text(encoding="utf-8")
        report(
            "WantedBy=multi-user.target" in text,
            "portal unit contains WantedBy=multi-user.target",
        )

    report(True, "rauc file not required")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
