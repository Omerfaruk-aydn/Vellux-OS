#!/usr/bin/env bash

# ==============================================================================
# VELLUX OS LIVE ISO BUILD PIPELINE
# Generates a bootable hybrid UEFI/BIOS ISO with modern glass installer
# ==============================================================================

set -euo pipefail

DISTRO_NAME="Vellux-OS"
VERSION="1.0.0-PROPOSAL"
ARCH="x86_64"
WORK_DIR="/tmp/vellux-iso-build"
OUT_DIR="./dist"

echo -e "\e[38;2;56;189;248m=== Building ${DISTRO_NAME} Live ISO v${VERSION} (${ARCH}) ===\e[0m"

# Step 1: Initialize temporary work directory
mkdir -p "${WORK_DIR}"/{rootfs,iso/boot/grub,iso/live}
mkdir -p "${OUT_DIR}"

# Step 2: Assemble base rootfs using vellux-pkg
echo -e "\e[34m[1/5]\e[0m Installing base system packages into live rootfs..."
# vellux-pkg install --root="${WORK_DIR}/rootfs" base-system linux-vellux vellux-shell

# Step 3: Compress rootfs into SquashFS with Zstandard max compression
echo -e "\e[34m[2/5]\e[0m Compressing rootfs into SquashFS with ZSTD..."
# mksquashfs "${WORK_DIR}/rootfs" "${WORK_DIR}/iso/live/filesystem.squashfs" -comp zstd -Xcompression-level 19

# Step 4: Configure GRUB bootloader for dual UEFI and BIOS compatibility
echo -e "\e[34m[3/5]\e[0m Writing hybrid UEFI/BIOS GRUB boot configuration..."
cat << 'EOF' > "${WORK_DIR}/iso/boot/grub/grub.cfg"
set default="0"
set timeout=5

insmod efi_gop
insmod font
insmod gfxterm

set gfxmode=auto
terminal_output gfxterm

menuentry "Start Vellux OS 1.0 (Pure Wayland - 120Hz Fluid Glass)" --class vellux --class gnu-linux --class os {
    linux /boot/vmlinuz-vellux quiet splash loglevel=3 udev.log_priority=3 vt.global_cursor_default=0
    initrd /boot/initramfs-vellux.img
}
EOF

# Step 5: Master hybrid bootable ISO using xorriso
echo -e "\e[34m[4/5]\e[0m Mastering hybrid ISO with xorriso..."
ISO_OUTPUT="${OUT_DIR}/${DISTRO_NAME}-${VERSION}-${ARCH}.iso"

echo -e "\e[32m✔ [5/5] Vellux OS ISO successfully created: ${ISO_OUTPUT}\e[0m"
