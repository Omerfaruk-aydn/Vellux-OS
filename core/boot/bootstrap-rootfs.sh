#!/usr/bin/env bash
# ==============================================================================
# VELLUX OS - KATMAN 1: SISTEM TABANI (ROOTFS) URETICISI
#
# Cekirdek, surucu/firmware, acilis (Plymouth/GRUB), kurulum (Calamares),
# sifreleme (LUKS), guvenlik (AppArmor/UFW/sysctl), guncelleme/geri alma,
# ag, ses, Bluetooth, sanal makine konuk araclari, yerlesik tarayici.
#
# Kullanim: bootstrap-rootfs.sh <rootfs_dizini>
# Ortam   : REPO_ROOT (varsayilan: bu betigin ust-ust dizini)
# ==============================================================================
set -euo pipefail

ROOTFS_DIR="$(realpath -m "${1:-./rootfs}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ASSET_DIR="${ASSET_DIR:-${REPO_ROOT}/build/assets}"
UBUNTU_CODENAME="noble"          # 24.04 LTS: Linux 6.8, Mesa 24, Wayland 1.22
MIRROR="${MIRROR:-http://archive.ubuntu.com/ubuntu/}"

c_info() { printf '\033[38;2;56;189;248m%s\033[0m\n' "$*"; }
c_step() { printf '\033[34m%s\033[0m %s\n' "$1" "$2"; }

mount_chroot() {
    sudo mkdir -p "${ROOTFS_DIR}"/{proc,sys,dev/pts,run}
    mountpoint -q "${ROOTFS_DIR}/proc"    || sudo mount -t proc proc "${ROOTFS_DIR}/proc"
    mountpoint -q "${ROOTFS_DIR}/sys"     || sudo mount -t sysfs sys "${ROOTFS_DIR}/sys"
    mountpoint -q "${ROOTFS_DIR}/dev"     || sudo mount --bind /dev "${ROOTFS_DIR}/dev"
    mountpoint -q "${ROOTFS_DIR}/dev/pts" || sudo mount -t devpts devpts "${ROOTFS_DIR}/dev/pts"
}
umount_chroot() {
    for m in dev/pts dev sys proc; do
        mountpoint -q "${ROOTFS_DIR}/${m}" 2>/dev/null && sudo umount -l "${ROOTFS_DIR}/${m}" || true
    done
}
trap umount_chroot EXIT

run_in_chroot() {   # run_in_chroot <isim> <betik-govdesi-stdin>
    local name="$1"
    sudo tee "${ROOTFS_DIR}/tmp/${name}.sh" >/dev/null
    sudo chmod +x "${ROOTFS_DIR}/tmp/${name}.sh"
    sudo chroot "${ROOTFS_DIR}" /usr/bin/env -i \
        HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin \
        DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 \
        /bin/bash "/tmp/${name}.sh"
    sudo rm -f "${ROOTFS_DIR}/tmp/${name}.sh"
}

c_info ">>> Vellux OS Katman 1: taban sistem uretiliyor -> ${ROOTFS_DIR}"

# ------------------------------------------------------------------------------
# [1/8] debootstrap
# ------------------------------------------------------------------------------
if [ ! -x "${ROOTFS_DIR}/bin/bash" ]; then
    c_step "[1/8]" "debootstrap (${UBUNTU_CODENAME}, minbase)..."
    sudo debootstrap --arch=amd64 --variant=minbase \
        --components=main,restricted,universe,multiverse \
        --include=systemd,systemd-sysv,udev,dbus,kmod,iproute2,netplan.io,wpasupplicant,sudo,ca-certificates,curl,gnupg,locales,tzdata,apt-utils \
        "${UBUNTU_CODENAME}" "${ROOTFS_DIR}" "${MIRROR}"
fi

# ------------------------------------------------------------------------------
# [2/8] Kimlik, depolar, apt ayarlari
# ------------------------------------------------------------------------------
c_step "[2/8]" "Sistem kimligi ve yazilim depolari..."
echo "vellux" | sudo tee "${ROOTFS_DIR}/etc/hostname" >/dev/null
sudo tee "${ROOTFS_DIR}/etc/hosts" >/dev/null <<'EOF'
127.0.0.1   localhost
127.0.1.1   vellux
::1         localhost ip6-localhost ip6-loopback
EOF

sudo tee "${ROOTFS_DIR}/etc/apt/sources.list" >/dev/null <<EOF
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-security main restricted universe multiverse
EOF

sudo tee "${ROOTFS_DIR}/etc/apt/apt.conf.d/90vellux" >/dev/null <<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::Retries "5";
Dpkg::Options { "--force-confdef"; "--force-confold"; };
EOF

# Kurulum sirasinda servisler chroot icinde baslamasin
sudo tee "${ROOTFS_DIR}/usr/sbin/policy-rc.d" >/dev/null <<'EOF'
#!/bin/sh
exit 101
EOF
sudo chmod +x "${ROOTFS_DIR}/usr/sbin/policy-rc.d"

# Ag (DNS) chroot icinde calissin
sudo cp -L /etc/resolv.conf "${ROOTFS_DIR}/etc/resolv.conf" 2>/dev/null || \
    echo "nameserver 1.1.1.1" | sudo tee "${ROOTFS_DIR}/etc/resolv.conf" >/dev/null

mount_chroot

# ------------------------------------------------------------------------------
# [3/8] Paketler
# ------------------------------------------------------------------------------
c_step "[3/8]" "Cekirdek, firmware, surucu, masaustu ve kurulum paketleri..."
run_in_chroot stage-packages <<'STAGE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update

echo ">>> Cekirdek, firmware, mikrokod, onyukleme, dosya sistemleri, sifreleme"
apt-get install -y \
    linux-image-generic linux-firmware amd64-microcode intel-microcode \
    live-boot initramfs-tools \
    cryptsetup cryptsetup-initramfs \
    btrfs-progs e2fsprogs dosfstools xfsprogs ntfs-3g exfatprogs \
    parted gdisk udisks2 efibootmgr squashfs-tools rsync \
    grub-common grub2-common grub-efi-amd64-bin grub-pc-bin grub-efi-amd64-signed shim-signed \
    plymouth plymouth-label plymouth-theme-spinner

# Ek cekirdek modulleri (genis donanim destegi: Wi-Fi/Bluetooth/ses/sanal GPU)
KVER="$(ls /lib/modules | sort -V | tail -n 1)"
apt-get install -y "linux-modules-extra-${KVER}"

echo ">>> Grafik, Wayland masaustu temeli"
apt-get install -y \
    mesa-vulkan-drivers mesa-va-drivers libgl1-mesa-dri libegl1 libgles2 libvulkan1 \
    libwayland-server0 libwayland-client0 libwayland-cursor0 libwayland-egl1 libinput10 \
    seatd sway swaybg swayidle swaylock waybar wofi foot xwayland \
    wl-clipboard grim slurp xdg-user-dirs xdg-utils \
    greetd \
    fonts-inter fonts-jetbrains-mono fonts-dejavu-core fonts-noto-color-emoji

echo ">>> Ses, ag, Bluetooth, guc"
apt-get install -y \
    pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils rtkit pavucontrol \
    network-manager wpasupplicant iw rfkill wireless-regdb bluez \
    iproute2 net-tools iputils-ping curl wget dnsutils isc-dhcp-client openssh-client \
    upower power-profiles-daemon acpid thermald fwupd

echo ">>> Guvenlik, sistem servisleri"
apt-get install -y \
    apparmor apparmor-utils apparmor-profiles ufw \
    polkitd pkexec gnupg libpam-systemd dbus-user-session \
    systemd-zram-generator systemd-oomd systemd-timesyncd \
    ubuntu-drivers-common pciutils usbutils lshw dmidecode

echo ">>> Yerlesik araclar, yerellestirme"
apt-get install -y \
    nano less bash-completion htop file zip unzip \
    locales tzdata kbd console-setup keyboard-configuration

echo ">>> Kurulum sihirbazi (Calamares)"
apt-get install -y \
    calamares qtwayland5 qml-module-qtquick2 qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts qml-module-qtquick-window2

echo ">>> Sanal makine konuk araclari (VirtualBox / VMware / QEMU / SPICE)"
for pkg in virtualbox-guest-utils open-vm-tools qemu-guest-agent spice-vdagent; do
    if ! apt-get install -y "$pkg"; then
        echo "UYARI: '$pkg' kurulamadi, atlaniyor."
    fi
done

echo ">>> Web tarayicisi (Mozilla resmi apt deposu; snap gerektirmez)"
install -d -m 0755 /etc/apt/keyrings
if curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc; then
    cat > /etc/apt/sources.list.d/mozilla.sources <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
    cat > /etc/apt/preferences.d/mozilla <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
    apt-get update
    apt-get install -y firefox firefox-l10n-tr || apt-get install -y epiphany-browser
else
    echo "UYARI: Mozilla deposu alinamadi; Epiphany kuruluyor."
    apt-get install -y epiphany-browser
fi
STAGE

# ------------------------------------------------------------------------------
# [4/8] Vellux katmani: overlay + Plymouth + Calamares gorselleri
# ------------------------------------------------------------------------------
c_step "[4/8]" "Vellux yapilandirma katmani (overlay) uygulaniyor..."
sudo rsync -rlD --chown=root:root "${REPO_ROOT}/core/overlay/" "${ROOTFS_DIR}/"
sudo chmod 0755 "${ROOTFS_DIR}"/usr/bin/vellux-* 2>/dev/null || true
sudo chmod 0600 "${ROOTFS_DIR}/etc/netplan/01-vellux-network-manager.yaml"

# Plymouth tema dosyalari
sudo install -d "${ROOTFS_DIR}/usr/share/plymouth/themes/vellux"
sudo install -m 0644 "${SCRIPT_DIR}/plymouth/vellux.plymouth" "${ROOTFS_DIR}/usr/share/plymouth/themes/vellux/"
sudo install -m 0644 "${SCRIPT_DIR}/plymouth/vellux.script"   "${ROOTFS_DIR}/usr/share/plymouth/themes/vellux/"
sudo install -m 0644 "${ASSET_DIR}/plymouth/"*.png            "${ROOTFS_DIR}/usr/share/plymouth/themes/vellux/"

# Calamares marka gorselleri
sudo install -m 0644 "${ASSET_DIR}/calamares/"*.png "${ROOTFS_DIR}/usr/share/calamares/branding/vellux/"

# ------------------------------------------------------------------------------
# [5/8] Yapilandirma, servisler, kullanicilar
# ------------------------------------------------------------------------------
c_step "[5/8]" "Servisler, guvenlik ve kullanicilar yapilandiriliyor..."
run_in_chroot stage-configure <<'STAGE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Yerel ayarlar
sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/; s/^# *\(tr_TR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone

# Gruplar (Calamares kullanici olustururken bunlari bekler)
for g in sudo adm cdrom plugdev video audio input render netdev bluetooth lpadmin autologin users; do
    getent group "$g" >/dev/null || groupadd -f "$g"
done

# Live oturum kullanicisi (kurulum sirasinda Calamares tarafindan kaldirilir)
id live >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo,video,audio,input,render,netdev,plugdev,bluetooth live
echo 'live:live' | chpasswd
echo 'live ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-vellux-live
chmod 0440 /etc/sudoers.d/99-vellux-live
chown -R live:live /home/live

# Servisler
for unit in \
    NetworkManager.service bluetooth.service systemd-timesyncd.service \
    fstrim.timer apparmor.service ufw.service upower.service \
    power-profiles-daemon.service acpid.service thermald.service \
    systemd-oomd.service rtkit-daemon.service fwupd.service \
    vellux-session.service vellux-driver-setup.service greetd.service \
    virtualbox-guest-utils.service vboxservice.service open-vm-tools.service \
    qemu-guest-agent.service; do
    systemctl enable "$unit" >/dev/null 2>&1 || echo "bilgi: ${unit} etkinlestirilemedi (paket yok olabilir)"
done
systemctl set-default graphical.target

# Kullanici baslangicinda PipeWire / WirePlumber
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 || true

# Guvenlik duvari: gelen baglantilar kapali, giden acik
if [ -f /etc/ufw/ufw.conf ]; then sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf; fi
if [ -f /etc/default/ufw ]; then
    sed -i 's/^DEFAULT_INPUT_POLICY=.*/DEFAULT_INPUT_POLICY="DROP"/; s/^DEFAULT_OUTPUT_POLICY=.*/DEFAULT_OUTPUT_POLICY="ACCEPT"/' /etc/default/ufw
fi

# initramfs: hizli zstd sikistirma, LUKS destegi, hazirda bekletme uyarisini sustur
mkdir -p /etc/initramfs-tools/conf.d
echo "COMPRESS=zstd" > /etc/initramfs-tools/conf.d/vellux-compress
echo "RESUME=none"   > /etc/initramfs-tools/conf.d/resume
grep -qx 'live-boot' /etc/initramfs-tools/modules 2>/dev/null || echo "live-boot" >> /etc/initramfs-tools/modules
echo "CRYPTSETUP=y" >> /etc/cryptsetup-initramfs/conf-hook 2>/dev/null || true

# Plymouth temasi (sifre istemi dahil) ve initramfs
install -d /etc/plymouth
cat > /etc/plymouth/plymouthd.conf <<'EOF'
[Daemon]
Theme=vellux
ShowDelay=0
DeviceTimeout=8
EOF
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme vellux
else
    update-alternatives --quiet --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
        /usr/share/plymouth/themes/vellux/vellux.plymouth 200
    update-alternatives --quiet --set default.plymouth /usr/share/plymouth/themes/vellux/vellux.plymouth
fi
update-initramfs -u -k all

# Kernel / initrd'e sabit yol (ISO uretimi icin)
ls -1 /boot
STAGE

# ------------------------------------------------------------------------------
# [6/8] Temizlik
# ------------------------------------------------------------------------------
c_step "[6/8]" "Temizlik ve kimlik sifirlama..."
run_in_chroot stage-clean <<'STAGE'
set -euo pipefail
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /tmp/* /root/.cache
rm -f /usr/sbin/policy-rc.d
: > /etc/machine-id
rm -f /var/lib/dbus/machine-id
rm -f /etc/ssh/ssh_host_*
rm -f /etc/resolv.conf && touch /etc/resolv.conf
find /var/log -type f -exec truncate -s 0 {} +
STAGE

# ------------------------------------------------------------------------------
# [7/8] Cekirdek ve initramfs'i ISO icin ayikla
# ------------------------------------------------------------------------------
c_step "[7/8]" "Cekirdek ve initramfs hazirlaniyor..."
mkdir -p ./iso_root/live
KERNEL_SRC="$(ls -1 "${ROOTFS_DIR}"/boot/vmlinuz-* | sort -V | tail -n 1)"
INITRD_SRC="$(ls -1 "${ROOTFS_DIR}"/boot/initrd.img-* | sort -V | tail -n 1)"
echo "Cekirdek : ${KERNEL_SRC}"
echo "Initramfs: ${INITRD_SRC}"
sudo cp "${KERNEL_SRC}" ./iso_root/live/vmlinuz
sudo cp "${INITRD_SRC}" ./iso_root/live/initrd.img
sudo chmod 644 ./iso_root/live/vmlinuz ./iso_root/live/initrd.img

# ------------------------------------------------------------------------------
# [8/8] Dogrulama
# ------------------------------------------------------------------------------
c_step "[8/8]" "Rootfs dogrulaniyor..."
umount_chroot
need=(
    usr/bin/vellux-update usr/bin/vellux-install usr/bin/vellux-session
    usr/bin/calamares
    etc/calamares/settings.conf etc/sysctl.d/99-vellux-hardening.conf
    usr/share/plymouth/themes/vellux/vellux.script usr/share/plymouth/themes/vellux/logo.png
    usr/lib/grub/x86_64-efi usr/lib/grub/i386-pc
)
missing=0
if ! sudo test -e "${ROOTFS_DIR}/usr/bin/firefox" && ! sudo test -e "${ROOTFS_DIR}/usr/bin/epiphany"; then
    echo "EKSIK: web tarayicisi (firefox/epiphany)" >&2; missing=1
fi
for f in "${need[@]}"; do
    if ! sudo test -e "${ROOTFS_DIR}/${f}"; then
        echo "EKSIK: ${f}" >&2; missing=1
    fi
done
if [ "${missing}" -ne 0 ]; then
    echo "Rootfs dogrulamasi basarisiz." >&2
    exit 1
fi
printf '\033[32m%s\033[0m\n' "OK  Katman 1 taban sistemi hazir."
