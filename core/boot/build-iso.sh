#!/usr/bin/env bash
# ==============================================================================
# VELLUX OS - ISO URETIM HATTI (CI ve yerel kullanim icin tek kaynak)
#
# 1) gorsel varliklari uretir (Plymouth / Calamares)
# 2) taban sistemi (rootfs) olusturur  -> bootstrap-rootfs.sh
# 3) Vellux yerel ikili dosyalarini ve yapilandirmayi yerlestirir
# 4) SquashFS (zstd) + hibrit UEFI/BIOS ISO uretir
#
# Ortam degiskenleri:
#   BIN_DIR   derlenmis vellux-* ikili dosyalarinin dizini (varsayilan: bin-artifacts)
#   OUT_ISO   cikti yolu (varsayilan: dist/Vellux-OS-1.1-x86_64.iso)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

ROOTFS_DIR="${ROOTFS_DIR:-${REPO_ROOT}/rootfs}"
BIN_DIR="${BIN_DIR:-${REPO_ROOT}/bin-artifacts}"
OUT_ISO="${OUT_ISO:-${REPO_ROOT}/dist/Vellux-OS-1.1-x86_64.iso}"
ASSET_DIR="${REPO_ROOT}/build/assets"
export REPO_ROOT ASSET_DIR

info() { printf '\033[38;2;56;189;248m%s\033[0m\n' "$*"; }

info "=== [1/4] Gorsel varliklar ==="
python3 core/boot/plymouth/gen-assets.py "${ASSET_DIR}"

info "=== [2/4] Taban sistem (Katman 1) ==="
sudo rm -rf iso_root && mkdir -p iso_root/boot/grub iso_root/live
./core/boot/bootstrap-rootfs.sh "${ROOTFS_DIR}"

info "=== [3/4] Vellux ikili dosyalari ve masaustu yapilandirmasi ==="
for b in vellux-pkg vellux-compositor vellux-shell vellux-term vellux-files vellux-settings; do
    if [ -f "${BIN_DIR}/${b}" ]; then
        sudo install -m 0755 "${BIN_DIR}/${b}" "${ROOTFS_DIR}/usr/bin/${b}"
    else
        echo "UYARI: ${BIN_DIR}/${b} bulunamadi" >&2
    fi
done

sudo mkdir -p "${ROOTFS_DIR}/etc/vellux"/{shaders,waybar,wofi}
sudo install -m 0644 compositor/config/sway.conf          "${ROOTFS_DIR}/etc/vellux/compositor.conf"
sudo install -m 0644 compositor/config/vellux-comp.conf   "${ROOTFS_DIR}/etc/vellux/vellux-comp.conf"
sudo install -m 0644 compositor/shaders/dual_kawase.frag  "${ROOTFS_DIR}/etc/vellux/shaders/dual_kawase.frag"
sudo install -m 0644 shell/waybar/config.jsonc            "${ROOTFS_DIR}/etc/vellux/waybar/config.jsonc"
sudo install -m 0644 shell/waybar/style.css               "${ROOTFS_DIR}/etc/vellux/waybar/style.css"
sudo install -m 0644 shell/wofi/config                    "${ROOTFS_DIR}/etc/vellux/wofi/config"
sudo install -m 0644 shell/wofi/style.css                 "${ROOTFS_DIR}/etc/vellux/wofi/style.css"
sudo install -m 0644 core/services/vellux-session.service "${ROOTFS_DIR}/etc/systemd/system/vellux-session.service"

sudo tee "${ROOTFS_DIR}/etc/os-release" >/dev/null <<'EOF'
NAME="Vellux OS"
PRETTY_NAME="Vellux OS 1.1"
ID=vellux
ID_LIKE="ubuntu debian"
VERSION="1.1"
VERSION_ID="1.1"
VERSION_CODENAME=noble
HOME_URL="https://github.com/Omerfaruk-aydn/Vellux-OS"
SUPPORT_URL="https://github.com/Omerfaruk-aydn/Vellux-OS/issues"
EOF
sudo chroot "${ROOTFS_DIR}" chown -R live:live /home/live || true

# Live oturum servisini etkinlestir (unit dosyasi yukarida yerlestirildi)
sudo chroot "${ROOTFS_DIR}" systemctl enable vellux-session.service
sudo chroot "${ROOTFS_DIR}" systemctl set-default graphical.target
if ! sudo test -L "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/vellux-session.service"; then
    echo "HATA: vellux-session.service etkinlestirilemedi" >&2
    exit 1
fi
# Kurulu sistemde greetd calisacak mi? (drop-in ile live'da kapali)
sudo test -f "${ROOTFS_DIR}/etc/systemd/system/greetd.service.d/10-not-live.conf"

info "=== [4/4] SquashFS ve ISO ==="
sudo rm -f iso_root/live/filesystem.squashfs
sudo mksquashfs "${ROOTFS_DIR}" iso_root/live/filesystem.squashfs \
    -comp zstd -Xcompression-level 19 -b 1M -noappend

cat > iso_root/boot/grub/grub.cfg <<'EOF'
set default=0
set timeout=4
insmod all_video
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm
set color_normal=white/black
set color_highlight=black/light-cyan

menuentry "Vellux OS 1.1" --class vellux {
    linux  /live/vmlinuz boot=live quiet splash loglevel=3 vt.global_cursor_default=0
    initrd /live/initrd.img
}
menuentry "Vellux OS 1.1 (Guvenli Grafik / nomodeset)" --class vellux {
    linux  /live/vmlinuz boot=live nomodeset loglevel=4
    initrd /live/initrd.img
}
menuentry "Vellux OS 1.1 (Ayrintili Onyukleme / Hata Ayiklama)" --class vellux {
    linux  /live/vmlinuz boot=live loglevel=7 systemd.log_level=debug console=tty0
    initrd /live/initrd.img
}
EOF

mkdir -p "$(dirname "${OUT_ISO}")"
sudo grub-mkrescue -o "${OUT_ISO}" iso_root -- -volid VELLUX_OS
sudo chown "$(id -u):$(id -g)" "${OUT_ISO}"
ls -lh "${OUT_ISO}"
SIZE_BYTES="$(stat -c %s "${OUT_ISO}")"
echo "ISO boyutu: ${SIZE_BYTES} bayt"
if [ "${SIZE_BYTES}" -ge 2147483648 ]; then
    echo "UYARI: ISO 2 GiB sinirini asiyor; GitHub Release varligi olarak yuklenemez." >&2
fi
info "=== ISO hazir: ${OUT_ISO} ==="
