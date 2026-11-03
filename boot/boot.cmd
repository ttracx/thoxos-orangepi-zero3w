# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 THOX.ai LLC
#
# ThoxOS U-Boot script for the Orange Pi Zero 3W (Allwinner A733, sun60iw2).
# Build host, not on the board:
#   mkimage -C none -A arm64 -T script -d boot.cmd boot.scr
# Install the resulting boot.scr into the vendor image's existing /boot.
# Do not dd boot0, the TOC/boot package, or any sector below the filesystem.
#
# The published vendor script is external/config/bootscripts/boot-sun60iw2.cmd
# in orangepi-build (installed as /boot/boot.cmd and /boot/boot.scr). It loads
# uImage with bootm at the U-Boot variables kernel_addr_r, ramdisk_addr_r, and
# fdt_addr_r. This script uses those same variables. It does not assign them.
# The only address set here is load_addr, and only when it is empty, to the
# scratch value that boot-sun60iw2.cmd already uses (0x43100000) for env and
# overlay loads. That is not a kernel load address.
#
# sun60iw2p1_t736_defconfig does not set CONFIG_BOOTCOMMAND. It does set
# CONFIG_DISTRO_DEFAULTS=y, so the image boots through distro boot, which
# sources this file when it is /boot/boot.scr. bootcmd_orangepi is not defined
# by that defconfig. It is tried only when the environment actually contains it.

# Distro bootcmd sources /boot/boot.scr. Falling through with `run bootcmd`
# would source this file again. Stop the second entry instead of looping.
if test "${thox_script_guard}" = "1"; then
	echo "THOXOS: boot script re-entered; not looping"
	exit
fi
setenv thox_script_guard 1

# prefix, devtype, and devnum come from the distro boot that sourced us.
# Do not guess an mmc unit. If prefix is empty (hand-sourced), use /boot/.
if test -z "${prefix}"; then
	setenv prefix /boot/
fi

# Scratch address for env import and for sourcing boot.scr.vendor.
# Same value as orangepi-build boot-sun60iw2.cmd. Not used for the kernel.
if test -z "${load_addr}"; then
	setenv load_addr 0x43100000
fi

# Merge ThoxOS keys. This is not a full environment replacement.
# Repo file boot/env/thoxos.env.txt is installed as /boot/thoxos.env.txt.
# /boot/env/thoxos.env.txt is accepted if the overlay keeps the repo layout.
if test -n "${devtype}"; then
	if test -e ${devtype} ${devnum} ${prefix}thoxos.env.txt; then
		echo "THOXOS: importing ${prefix}thoxos.env.txt"
		load ${devtype} ${devnum} ${load_addr} ${prefix}thoxos.env.txt
		env import -t ${load_addr} ${filesize}
	elif test -e ${devtype} ${devnum} ${prefix}env/thoxos.env.txt; then
		echo "THOXOS: importing ${prefix}env/thoxos.env.txt"
		load ${devtype} ${devnum} ${load_addr} ${prefix}env/thoxos.env.txt
		env import -t ${load_addr} ${filesize}
	else
		echo "THOXOS: no thoxos.env.txt under ${prefix}; using defaults"
	fi
	# Vendor editable env. Imported after ThoxOS so a local override wins.
	# Stock sun60iw2.txt only sets verbosity=1 and bootlogo=false.
	if test -e ${devtype} ${devnum} ${prefix}orangepiEnv.txt; then
		echo "THOXOS: importing ${prefix}orangepiEnv.txt"
		load ${devtype} ${devnum} ${load_addr} ${prefix}orangepiEnv.txt
		env import -t ${load_addr} ${filesize}
	fi
else
	echo "THOXOS: devtype unset; cannot load from the boot filesystem"
fi

# Default SKU. Anything already in the environment (saved env or the files
# imported above) wins.
if test -z "${thox_sku}"; then
	setenv thox_sku thoxmini
fi
echo "THOXOS: thox_sku=${thox_sku} carrier=opi3w"

# DTB. Prefer a ThoxOS SKU blob if the image actually contains it.
# Otherwise the vendor name from orangepizero3w.conf:
#   BOOT_FDT_FILE=allwinner/sun60i-a733-orangepi-zero3w.dtb
# which boot-sun60iw2.cmd loads as ${prefix}dtb/${fdtfile}.
# Search that directory, then a flat dtb/ directory, then /boot itself.
setenv thox_fdt
if test -n "${devtype}"; then
	if test -e ${devtype} ${devnum} ${prefix}dtb/allwinner/sun60i-a733-${thox_sku}-opi3w.dtb; then
		setenv thox_fdt ${prefix}dtb/allwinner/sun60i-a733-${thox_sku}-opi3w.dtb
	elif test -e ${devtype} ${devnum} ${prefix}dtb/sun60i-a733-${thox_sku}-opi3w.dtb; then
		setenv thox_fdt ${prefix}dtb/sun60i-a733-${thox_sku}-opi3w.dtb
	elif test -e ${devtype} ${devnum} ${prefix}sun60i-a733-${thox_sku}-opi3w.dtb; then
		setenv thox_fdt ${prefix}sun60i-a733-${thox_sku}-opi3w.dtb
	elif test -e ${devtype} ${devnum} ${prefix}dtb/allwinner/sun60i-a733-orangepi-zero3w.dtb; then
		setenv thox_fdt ${prefix}dtb/allwinner/sun60i-a733-orangepi-zero3w.dtb
	elif test -e ${devtype} ${devnum} ${prefix}dtb/sun60i-a733-orangepi-zero3w.dtb; then
		setenv thox_fdt ${prefix}dtb/sun60i-a733-orangepi-zero3w.dtb
	elif test -e ${devtype} ${devnum} ${prefix}sun60i-a733-orangepi-zero3w.dtb; then
		setenv thox_fdt ${prefix}sun60i-a733-orangepi-zero3w.dtb
	fi
fi

# Kernel. A ThoxOS raw arm64 Image is booted with booti.
# The vendor jammy image ships uImage and its script uses bootm.
# CONFIG_CMD_BOOTI is not spelled out in sun60iw2p1_t736_defconfig;
# CONFIG_DISTRO_DEFAULTS=y usually selects it. If booti is missing or
# returns, the failure path below falls through.
setenv thox_kernel
setenv thox_bootmethod
if test -n "${devtype}"; then
	if test -e ${devtype} ${devnum} ${prefix}Image; then
		setenv thox_kernel ${prefix}Image
		setenv thox_bootmethod booti
	elif test -e ${devtype} ${devnum} ${prefix}uImage; then
		setenv thox_kernel ${prefix}uImage
		setenv thox_bootmethod bootm
	fi
fi

if test -n "${thox_kernel}"; then
	if test -n "${thox_fdt}"; then
		echo "THOXOS: kernel ${thox_kernel} via ${thox_bootmethod}"
		echo "THOXOS: dtb ${thox_fdt}"

		# Append. Do not replace bootargs when the vendor environment
		# already has a cmdline. The kernel keeps the last loglevel=.
		setenv thox_cmdline "quiet loglevel=4 console=ttyS0,115200 console=tty1 thox.sku=${thox_sku} thox.carrier=opi3w cgroup_enable=memory swapaccount=1"
		if test -n "${bootargs}"; then
			echo "THOXOS: appending to existing bootargs"
			setenv bootargs "${bootargs} ${thox_cmdline}"
		else
			# No cmdline in the environment. Build the root= line from
			# boot-sun60iw2.cmd: PARTUUID of partition 1 on the device
			# distro boot already selected. v1 is the vendor single root.
			# clk_ignore_unused is part of that same vendor script.
			# cgroup_enable=cpuset and cgroup_memory=1 are its
			# docker_optimizations=on default; the ThoxOS string still
			# supplies cgroup_enable=memory and swapaccount=1.
			echo "THOXOS: no vendor bootargs; synthesizing root= then appending"
			if test -z "${rootdev}"; then
				if part uuid ${devtype} ${devnum}:1 partuuid; then
					setenv rootdev PARTUUID=${partuuid}
				else
					echo "THOXOS: part uuid failed; not inventing root="
				fi
			fi
			if test -z "${rootdev}"; then
				echo "THOXOS: rootdev unset; not booting with an empty root="
			else
				if test -z "${rootfstype}"; then
					setenv rootfstype ext4
				fi
				setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} consoleblank=0 clk_ignore_unused cgroup_enable=cpuset cgroup_memory=1 ${extraargs} ${extraboardargs} ${thox_cmdline}"
			fi
		fi

		# Refuse to invent kernel or fdt addresses. Both must already
		# be in the vendor environment, as boot-sun60iw2.cmd assumes.
		# A failed load must not abort the script before the fallback.
		if test -z "${bootargs}"; then
			echo "THOXOS: bootargs unset after cmdline setup; skipping boot"
		elif test -z "${kernel_addr_r}"; then
			echo "THOXOS: kernel_addr_r unset; not inventing a load address"
		elif test -z "${fdt_addr_r}"; then
			echo "THOXOS: fdt_addr_r unset; not inventing a load address"
		elif load ${devtype} ${devnum} ${kernel_addr_r} ${thox_kernel}; then
			if load ${devtype} ${devnum} ${fdt_addr_r} ${thox_fdt}; then
				if test -e ${devtype} ${devnum} ${prefix}uInitrd; then
					if test -n "${ramdisk_addr_r}"; then
						if load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd; then
							echo "THOXOS: ${thox_bootmethod} with uInitrd"
							if test "${thox_bootmethod}" = "booti"; then
								if booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}; then
									echo "THOXOS: booti returned"
								else
									echo "THOXOS: booti failed"
								fi
							else
								if bootm ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}; then
									echo "THOXOS: bootm returned"
								else
									echo "THOXOS: bootm failed"
								fi
							fi
						else
							echo "THOXOS: load uInitrd failed"
						fi
					else
						echo "THOXOS: uInitrd present but ramdisk_addr_r unset; booting without initrd"
						if test "${thox_bootmethod}" = "booti"; then
							if booti ${kernel_addr_r} - ${fdt_addr_r}; then
								echo "THOXOS: booti returned"
							else
								echo "THOXOS: booti failed"
							fi
						else
							if bootm ${kernel_addr_r} - ${fdt_addr_r}; then
								echo "THOXOS: bootm returned"
							else
								echo "THOXOS: bootm failed"
							fi
						fi
					fi
				else
					echo "THOXOS: no ${prefix}uInitrd; booting without initrd"
					if test "${thox_bootmethod}" = "booti"; then
						if booti ${kernel_addr_r} - ${fdt_addr_r}; then
							echo "THOXOS: booti returned"
						else
							echo "THOXOS: booti failed"
						fi
					else
						if bootm ${kernel_addr_r} - ${fdt_addr_r}; then
							echo "THOXOS: bootm returned"
						else
							echo "THOXOS: bootm failed"
						fi
					fi
				fi
			else
				echo "THOXOS: load dtb failed"
			fi
		else
			echo "THOXOS: load kernel failed"
		fi
	else
		echo "THOXOS: dtb missing; wanted sun60i-a733-${thox_sku}-opi3w.dtb or sun60i-a733-orangepi-zero3w.dtb"
	fi
else
	echo "THOXOS: no ${prefix}Image and no ${prefix}uImage"
fi

# Files were missing, or booti/bootm returned. Hand off.
# 1. Preserved vendor script, if the installer copied the original boot.scr
#    to boot.scr.vendor before replacing it.
# 2. bootcmd_orangepi, only if that variable exists. It is not in the
#    sun60iw2p1_t736 defconfig.
# 3. Distro bootcmd. The guard at the top exits if that sources us again.
echo "THOXOS: falling through to vendor boot"
if test -n "${devtype}"; then
	if test -e ${devtype} ${devnum} ${prefix}boot.scr.vendor; then
		echo "THOXOS: sourcing ${prefix}boot.scr.vendor"
		if load ${devtype} ${devnum} ${load_addr} ${prefix}boot.scr.vendor; then
			source ${load_addr}
		else
			echo "THOXOS: load boot.scr.vendor failed"
		fi
	else
		echo "THOXOS: no ${prefix}boot.scr.vendor"
	fi
fi
if test -n "${bootcmd_orangepi}"; then
	echo "THOXOS: run bootcmd_orangepi"
	run bootcmd_orangepi
else
	echo "THOXOS: bootcmd_orangepi is not set"
fi
echo "THOXOS: run bootcmd"
run bootcmd
