# Archus-b (Windows Edition) — Auto Arch USB Boot Medium Creator

> Prepare a bootable **Arch Linux** USB **from Windows 10/11** using **WSL2 + usbipd-win**. This edition automates prerequisites on Windows, passes a physical USB stick into WSL (Debian), and then reuses the Linux pipeline to partition, download, verify and install Arch on the USB device.

---

https://www.youtube.com/watch?v=n-ilkv_zAYU - Link where you can find information about the script's capabilities and how it works.

---

# Necessary configurations:
- UEFI  [OK]
- SECURE BOOT  [NO]

---

- USB storage capacity not greater than < 32 GB (Larger are not recognized during boot [EFI partition in FAT format])
- The USB drive should not contain an EFI partition before mounting in WSL: 
![obraz](https://github.com/user-attachments/assets/4ede94f0-28da-42ce-9c68-6e8ba58d172e)

---

## Table of contents
- Overview
- Features
- Requirements (Windows host)
- Quick Start (Windows)
- What the Windows scripts do
- How it bridges into the Linux pipeline
- Configuration & Files
- Repository structure (Windows + Linux)
- Software info
- Additional INFO

---

## Overview
This Windows edition wraps the original Archus-b flow with a **PowerShell + Batch** bootstrap that:
1) Ensures **WSL2** and required Windows optional features are enabled,
2) Installs or verifies **usbipd-win**,
3) Attaches a chosen **USB mass-storage device** to the WSL Debian distro,
4) Launches the Linux entrypoint to perform the actual creation of the Arch USB medium.

---

## Features
- **One-click launcher on Windows** (`arch_install_win.bat`) that elevates to admin, runs PowerShell bootstrap and resumes after reboot.
- **Environment verification**: WSL2, VirtualMachinePlatform, HypervisorPlatform; auto-enable if disabled.
- **usbipd-win handling**: auto-download latest x64 MSI via GitHub API if missing; silent install.
- **USB pass-through**: interactive selection of the correct device (search for *USB Mass Storage Device*), bind/attach to **WSL: Debian**.
- **Resilience**: simple `progress.inf` tracking + resume after reboot via `after_reboot.bat` in Startup folder.
- **Bridges to Linux pipeline** (same steps as Linux edition: partition → download+verify → extract → chroot stage 1 → chroot stage 2 → GRUB).

---

## Requirements (Windows host)
- **Windows 10/11** with admin rights.
- **WSL2** available (the script enables required features on first run and can reboot):
  - `Microsoft-Windows-Subsystem-Linux`
  - `VirtualMachinePlatform`
  - `HypervisorPlatform`
- **Debian** WSL distro (installed automatically if missing).
- **usbipd-win** (installed automatically if missing).
- **Internet connectivity** (checks against `8.8.8.8`).
- A **USB flash drive** to be fully reformatted. *All data on the selected USB will be destroyed.*

> PowerShell is executed with `-ExecutionPolicy Bypass` from the batch launcher.

---

## Quick Start (Windows)
From an **elevated** terminal (or by double-clicking, the batch will elevate):

```bat
arch_install_win.bat
```

The script will:
1) Maximize a PowerShell window and run `resources\arch_install.ps1`.
2) Verify internet, set keyboard layout (using `set_keymapping.ps1`), check/install **usbipd-win**, enable WSL features and configure `~\.wslconfig` to `networkingMode = nat`.
3) Create a **Startup** entry (`after_reboot.bat`) and ask to reboot if needed.
4) After reboot, it will automatically resume, ensure **Debian** is present, ask you to **select a USB device**, pass it to WSL, then run the Linux flow.

When finished, the USB is ready to boot via UEFI.

---

## What the Windows scripts do

### `arch_install_win.bat`
- Elevates to Administrator (re-invokes itself with `runAs`).
- Runs PowerShell: `powershell -WindowStyle Maximize -ExecutionPolicy Bypass -File .\resources\arch_install.ps1`.

### `resources/arch_install.ps1`
- **Banner/animation** + version.
- **Internet check** loop using `Test-Connection 8.8.8.8`.
- **Keyboard layout** setup via `resources/scripts/set_keymapping.ps1`; logs in `resources/Files/keyboard_layout.inf`.
- **usbipd-win**:
  - If missing, queries GitHub releases API, downloads latest x64 `.msi` into `resources/Files/usbipd.msi`, installs silently, verifies path `C:\Program Files\usbipd-win\usbipd.exe`.
- **Windows Optional Features**: enables WSL2 + virtualization features; writes `~\.wslconfig` with `networkingMode = nat`.
- **Resume after reboot**: writes `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\after_reboot.bat` to continue automatically, then prompts to reboot.
- **Debian WSL**: `wsl --install -d Debian --no-launch` if missing; `wsl --update`.
- **USB pass-through**:
  - Lists USB devices via `usbipd list`, prompts to choose the `BUSID`.
  - Binds and attaches the device to WSL **Debian**.
  - Kicks a helper in WSL (`init_wsl_deb.sh`) then runs the Linux entrypoint (`arch_main_win.sh`).
  - On completion, detaches and unbinds all USB devices from WSL.

### `arch_main_win.sh` (inside WSL)
- Copies the repository directory into `/home/` and executes the standard Linux entrypoint: `sudo bash /home/arch_install/arch_main.sh`.

---

## How it bridges into the Linux pipeline
Once inside WSL (Debian), **the Linux scripts you already know** take over:
1) `check_packages.sh` (APT) → 2) `fdisk_create.sh` (USB partitioning) → 3) `dowload_and_check.sh` (mirrors + GPG verify) → 4) `extrackt_and_move.sh` (extract bootstrap) → 5) `jail_bootstrap.sh` (chroot orchestration) → 6) `in_chroot.sh` → 7) `in_chroot2.sh` → bootable USB.

---

## Configuration & Files
- `resources/Files/progress.inf` — simple INI-style flags used to track prerequisites (keyboard, usbipd, WinFeature_*, Restart). Autogenerated/updated by PowerShell.
- `resources/Files/keyboard_layout.inf` — stores selected keyboard layout (read by PowerShell step).
- `~/.wslconfig` — forced to `networkingMode = nat` to avoid `virtioproxy` errors with usbipd-win.
- `Startup/after_reboot.bat` — temporary resume script removed after use.

> Linux-side configuration (mirrors, countries list, etc.) remains the same as in the Linux README.

---

## Repository structure (Windows + Linux)
```
├── arch_install_win.bat               # Windows launcher (elevates, runs PowerShell)
├── arch_main_win.sh                   # WSL bridge → runs Linux arch_main.sh
├── arch_main.sh                       # Linux entrypoint (requires root)
├── resources/
   ├── arch_install.ps1               # Windows bootstrap (WSL + usbipd + USB attach)
   ├── Files/
   │   ├── progress.inf               # Runtime progress tracking
   │   └── keyboard_layout.inf        # Keyboard layout info
   └── scripts/
       ├── set_keymapping.ps1         # Keyboard mapping helper (Windows)
       ├── init_wsl_deb.sh            # Helper invoked inside WSL before main
       ├── check_packages.sh
       ├── fdisk_create.sh
       ├── dowload_and_check.sh
       ├── extrackt_and_move.sh
       ├── jail_bootstrap.sh
       ├── in_chroot.sh
       ├── in_chroot2.sh
       ├── replace_hooks.sh
       ├── umount_jail.sh
       ├── Error_handling/
       │   └── pacman_retrying.sh     # Required at runtime (copied into chroot)
       └── ramroot_1.1/               # RAMROOT helper (external content)
```

# Software info
The script uses tools distributed by MS and a verified Arch linux image available on the official project website.
- MS WSL - https://learn.microsoft.com/en-us/windows/wsl/install
- usbipd-win - https://github.com/dorssel/usbipd-win
- bootstrap source - https://archlinux.org/download
- ramroot - https://github.com/arcmags/ramroot

# Additional INFO ;)
If you think I deserve a ☕️, you can send a few 🪙 to Bitcoin address:

1HAK5X4JjnBsJyAaQnpwMMkJRi1MeV7hp3
