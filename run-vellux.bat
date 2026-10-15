@echo off
title Starting Vellux OS 1.0 (QEMU Virtual Machine)
echo ===================================================
echo     STARTING VELLUX OS 1.0 IN VIRTUAL MACHINE
echo ===================================================
echo ISO: D:\Vellux-OS\Vellux-OS-1.0-x86_64.iso
echo RAM: 4096 MB (4 GB)
echo CPU: 4 Cores
echo Display: Hardware Direct Scanout (GTK / VirtIO GPU)
echo ===================================================
echo.
wsl -d Ubuntu -e bash -c "export DISPLAY=:0; export WAYLAND_DISPLAY=wayland-0; qemu-system-x86_64 -m 4096 -smp 4 -cdrom /mnt/d/Vellux-OS/Vellux-OS-1.0-x86_64.iso -boot d -vga virtio -display gtk,gl=on"
pause
