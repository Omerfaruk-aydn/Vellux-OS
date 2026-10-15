#!/usr/bin/env bash
# ==============================================================================
# VELLUX OS PRODUCTION BOOTSTRAPPER & LIVE ROOTFS GENERATOR
# ==============================================================================
set -euo pipefail

ROOTFS_DIR="${1:-./rootfs}"
UBUNTU_CODENAME="noble" # 24.04 LTS (Modern Linux Kernel 6.8+, Mesa 24+, Wayland 1.22+)

echo -e "\e[38;2;56;189;248m>>> Bootstrapping Vellux OS Live Rootfs into: ${ROOTFS_DIR}\e[0m"

# 1. Debootstrap minimal base system
if [ ! -f "${ROOTFS_DIR}/bin/bash" ]; then
    echo -e "\e[34m[1/6]\e[0m Running debootstrap for ${UBUNTU_CODENAME} base..."
    sudo debootstrap \
        --arch=amd64 \
        --variant=minbase \
        --include=systemd,udev,dbus,kmod,iproute2,netplan.io,wpasupplicant,sudo \
        "${UBUNTU_CODENAME}" \
        "${ROOTFS_DIR}" \
        http://archive.ubuntu.com/ubuntu/
fi

# 2. Configure Hostname, Locales, and Repositories
echo -e "\e[34m[2/6]\e[0m Configuring system identities and software repositories..."
echo "vellux" | sudo tee "${ROOTFS_DIR}/etc/hostname" > /dev/null

cat << 'EOF' | sudo tee "${ROOTFS_DIR}/etc/hosts" > /dev/null
127.0.0.1   localhost
127.0.1.1   vellux
::1         localhost ip6-localhost ip6-loopback
EOF

cat << 'EOF' | sudo tee "${ROOTFS_DIR}/etc/apt/sources.list" > /dev/null
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

# 3. Chroot execution: Install Kernel, Drivers, Wayland & Audio Stack
echo -e "\e[34m[3/6]\e[0m Installing Linux Kernel, GPU/Audio drivers, and Wayland in chroot..."
sudo chroot "${ROOTFS_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
        linux-image-generic \
        linux-firmware \
        live-boot \
        initramfs-tools \
        mesa-vulkan-drivers \
        mesa-va-drivers \
        libgl1-mesa-dri \
        libwayland-server0 \
        libwayland-client0 \
        libwayland-cursor0 \
        libwayland-egl1 \
        libegl1 \
        libgles2 \
        libvulkan1 \
        libinput10 \
        seatd \
        sway \
        swaybg \
        waybar \
        wofi \
        foot \
        xwayland \
        pipewire \
        wireplumber \
        network-manager \
        iproute2 \
        net-tools \
        iputils-ping \
        curl \
        wget \
        dnsutils \
        isc-dhcp-client \
        chromium-browser \
        fonts-inter \
        fonts-jetbrains-mono \
        ca-certificates

    # Ensure live-boot is embedded in initramfs
    echo "live-boot" >> /etc/initramfs-tools/modules
    update-initramfs -u -k all

    # Configure NetworkManager & Netplan for automatic DHCP on all interfaces
    mkdir -p /etc/netplan
    cat << 'NETCFG' > /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: NetworkManager
NETCFG
    chmod 600 /etc/netplan/01-network-manager-all.yaml

    # Enable NetworkManager & PipeWire
    systemctl enable NetworkManager.service || true
    systemctl enable systemd-resolved.service || true

    # Clean package caches to minimize ISO size
    apt-get clean
    rm -rf /var/lib/apt/lists/*
"

# 4. Create Vellux Default Live User
echo -e "\e[34m[4/6]\e[0m Creating live session user (vellux)..."
sudo chroot "${ROOTFS_DIR}" /bin/bash -c "
    useradd -m -s /bin/bash -G sudo,video,audio,input,render vellux || true
    echo 'vellux:vellux' | chpasswd
    echo 'vellux ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-vellux-live
    chmod 0440 /etc/sudoers.d/99-vellux-live
"

# 5. Extract Kernel and Initramfs for GRUB Live Boot
echo -e "\e[34m[5/6]\e[0m Extracting kernel and live initramfs to staging boot directory..."
mkdir -p ./iso_root/live
KERNEL_SRC=$(ls -1 "${ROOTFS_DIR}/boot/vmlinuz-"* | head -n 1)
INITRD_SRC=$(ls -1 "${ROOTFS_DIR}/boot/initrd.img-"* | head -n 1)

echo "Copying Kernel: ${KERNEL_SRC}"
sudo cp "${KERNEL_SRC}" ./iso_root/live/vmlinuz
echo "Copying Initramfs: ${INITRD_SRC}"
sudo cp "${INITRD_SRC}" ./iso_root/live/initrd.img

sudo chmod 644 ./iso_root/live/vmlinuz ./iso_root/live/initrd.img

echo -e "\e[32m✔ [6/6] Full base rootfs bootstrap completed successfully.\e[0m"
