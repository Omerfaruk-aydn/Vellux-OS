@echo off
title Vellux OS 1.0 - Windows Native WHPX Hardware Accelerated
echo ===================================================================
echo     LAUNCHING VELLUX OS 1.0 (Windows Hypervisor WHPX Accelerated)
echo ===================================================================
echo Target ISO: D:\Vellux-OS\Vellux-OS-1.0-x86_64.iso
echo Memory: 4096 MB
echo CPU Cores: 4
echo Accelerator: WHPX (Windows Hypervisor Platform - Direct AMD-V)
echo ===================================================================
echo.
"C:\Program Files\qemu\qemu-system-x86_64.exe" -accel whpx -accel tcg -m 4096 -smp 4 -cdrom "D:\Vellux-OS\Vellux-OS-1.0-x86_64.iso" -boot d -vga std
pause
