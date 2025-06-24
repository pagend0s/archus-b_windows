# archus-b_windows

Fully automated creation of a bootable (UEFI) Archlinux system on USB loaded into RAM.

https://www.youtube.com/watch?v=n-ilkv_zAYU - Link where you can find information about the script's capabilities and how it works.

The script creates partitions (two are defined: BOOT and ROOT). It retrieves the system's location (based on the local time zone settings). To download the bootstrap, it uses the location to select the appropriate link from https://archlinux.org/download/. It verifies the downloaded bootstrap image using the certificate (always the latest version). If the certificate verification fails, the script selects the next location and retries the verification. Upon successful verification, the files are extracted. Mirrors are also selected based on the location. After successfully mounting /sys /proc /run and /dev the script performs a chroot and continues installing the necessary packages and configuring the system. In the final phase, a RAMROOT hook (a slightly modified version of the arcmags project on https://github.com/arcmags/ramroot) is added, enabling the root filesystem to be loaded into RAM.

# Necessary configurations:
UEFI  [OK]
SECURE BOOT  [NO]

The USB drive should not contain an EFI partition before mounting in WSL: 
![obraz](https://github.com/user-attachments/assets/4ede94f0-28da-42ce-9c68-6e8ba58d172e)

# Software info
The script uses tools distributed by MS and a verified Arch linux image available on the official project website.
- MS WSL
- usbipd-win - https://github.com/dorssel/usbipd-win
- bootstrap source - https://archlinux.org/download

# Additional INFO ;)
If you think I deserve a ☕️, you can send a few 🪙 to Bitcoin address:

1HAK5X4JjnBsJyAaQnpwMMkJRi1MeV7hp3
