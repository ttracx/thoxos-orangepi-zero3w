<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 THOX.ai LLC
-->

# GPU — Imagination BXM-4-64 MC1

The SoC GPU is an Imagination BXM-4-64 MC1. The closed driver exposes
OpenGL ES 3.2, Vulkan 1.3, and OpenCL 3.0. ThoxOS does not ship that
driver and does not start it.

The ThoxOS image does not start a display server. No compositor unit
is shipped. Do not enable a compositor service to "try the GPU".

Community reports under the label pvr-a733-armbian say a live compositor
can deadlock the kernel. Off-screen OpenCL / Vulkan has been demonstrated
in that community work. ThoxOS has not reproduced either result on
`Orangepizero3w_1.0.2_ubuntu_jammy_server_linux6.6.98`.

A future off-screen OpenCL path is allowed only after that deadlock is
retested on this exact image, with the display server still absent.
Until that retest is recorded, the PowerVR driver stays unstarted
(`vendor-pvr-gpu` status `do-not-start` in the firmware manifest).
