<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 THOX.ai LLC
-->

# NPU (Allwinner A733)

The vendor device tree enables node `&npu`. Vendor material describes
up to 3 TOPS INT8 and mixed INT8 / INT16 / FP16 / BF16. Those are vendor
claims. This tree does not measure TOPS, does not ship a model, and does
not ship userspace.

Userspace is vendor software. It is not rehosted in git. Do not add
`.so`, `.a`, or `.bin` files under this directory.

## Future install (not done here)

A later package, built and stored outside this repository, may:

1. Take the NPU libraries from the vendor image or vendor SDK only.
2. Install the shared objects into `/usr/lib/thox/npu/`
   (one subdirectory is allowed).
3. Leave the loader path pointing at that directory, not at a git checkout.
4. Run `thoxos-npu-probe`.

Until that package exists, the probe must fail. Do not stub a library
to force success.

## Probe contract

`thoxos-npu-probe` is a POSIX `sh` script. It does not load the NPU.

| Exit | Meaning |
| --- | --- |
| 0 | A vendor NPU node is visible under `/sys` or `/proc/device-tree` (or the devicetree sysfs mirror), and at least one regular file matching `*.so` or `*.so.*` is present under `/usr/lib/thox/npu`. |
| 3 | That node is not visible. Message states the node is absent. |
| 4 | The node is visible, but `/usr/lib/thox/npu` is missing or has no shared library. |

Exit 0 requires both conditions. Anything short of that is a failure.
The script never prints a measured TOPS figure.
