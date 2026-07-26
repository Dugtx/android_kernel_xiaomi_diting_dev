# Flashing and recovery / 刷写与恢复

## Preconditions / 前置条件

- Confirm the device reports codename `diting`.
- Confirm the bootloader is unlocked.
- Keep the exact stock `boot.img` for the installed ROM.
- Record the active slot and hashes of both boot partitions.
- Use an image repacked from an unmodified stock ramdisk.

## Temporary test first / 必须先临时启动

```bash
adb reboot bootloader
fastboot getvar product
fastboot getvar current-slot
fastboot boot boot-diting-candidate.img
```

Do not use `fastboot flash` for a first test. A candidate passes only after:

- Android reaches `sys.boot_completed=1`
- SELinux remains Enforcing
- Wi-Fi, camera, audio, telephony and sensors operate
- Xiaomi/Qualcomm vendor modules load without unknown-symbol or CRC errors
- the expected KernelSU and container configuration is present
- at least one normal reboot returns to the persistent daily kernel

## Recovery / 恢复

If the phone stays at the first screen or boot animation:

1. hold the hardware key combination to return to fastboot;
2. boot or flash the verified stock image for the active slot;
3. do not relock the bootloader;
4. collect early `dmesg`, module-load and Android init logs before retrying.

For an A/B device, changing the active slot is not a universal recovery method:
slot firmware and dynamic partitions must belong to a consistent ROM build.
Prefer restoring the verified boot image that matches the installed system.

## Persistent installation / 持久安装

Persistent flashing is a separate, explicit action after temporary-boot
acceptance. Write only the intended boot slot, verify the result and retain a
known-good fallback. The repository never assumes permission to erase user
data, flash firmware or lock the bootloader.
