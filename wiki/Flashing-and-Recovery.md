# Flashing and recovery / 安装与恢复

This project changes the kernel in the boot chain. Read the complete recovery
section and prepare a matching stock image before installing anything.

本项目会修改启动链中的内核。安装前必须读完恢复章节，并准备与当前 ROM 完全
匹配的原厂镜像。

## Supported target / 支持目标

- Device: Redmi K50 Ultra
- Codename: `diting`
- ROM: HyperOS `OS2.0.211.0.VLFCNXM`, Android 15
- Bootloader: unlocked

Other ROMs and devices are not supported. Do not infer compatibility from the
same Android version or SoC.

## Before installation / 安装前

1. Confirm the device and active slot:

   ```bash
   adb shell getprop ro.product.device
   adb reboot bootloader
   fastboot getvar product
   fastboot getvar current-slot
   ```

2. Keep the untouched stock `boot.img` from the exact installed ROM.
3. Verify the downloaded ZIP with the release `SHA256SUMS` file.
4. Confirm that Fastboot detects the device and that you know how to restore
   the stock boot image.
5. Do not relock the bootloader while a modified kernel is installed.

KernelSU-Next variants require a clean stock ramdisk. Restore the matching
stock boot before installation if Magisk or another tool has patched the
ramdisk. The installer aborts on a non-stock ramdisk rather than creating a
KernelSU/Magisk dual-root setup.

## What the ZIP changes / ZIP 修改内容

The release ZIP uses AnyKernel3 and targets only `diting`. It:

- selects the current active boot slot;
- unpacks the existing boot image;
- replaces only the kernel `Image`;
- preserves the existing ramdisk and other boot-image components;
- repacks and writes the boot image back to the active slot.

“Only replaces Image” does not make the package ROM-independent. The new
kernel still has to match the Xiaomi vendor-module ABI in the installed ROM.

发布 ZIP 使用 AnyKernel3，只替换当前活动 boot 槽里的内核 `Image` 并保留
ramdisk。这并不代表跨 ROM 兼容，内核仍必须匹配已安装系统的 vendor 模块 ABI。

## Install the release ZIP / 安装发布 ZIP

1. Download the intended variant from
   [Releases](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases).
2. Verify its SHA-256 and re-check the package name.
3. Flash it with an AnyKernel3-compatible kernel flasher or recovery.
4. Read the installer output before rebooting; a device or ramdisk check
   failure must not be ignored.
5. Keep the phone connected during the first boot until normal Android startup
   and recovery access are confirmed.

`v1.0.0-rc1` remains a Pre-release because its AnyKernel3 install-and-recovery
path has not yet completed a public on-device rehearsal. Users without a
tested Fastboot recovery path should wait for a stable release.

## First boot checklist / 首次启动检查

After installation, check normal phone functions before configuring Docker or
performance tools:

- Android reaches the launcher and remains stable after another reboot;
- SELinux remains Enforcing;
- Wi-Fi, mobile data, calls, camera, audio, Bluetooth, NFC, and sensors work;
- no Xiaomi/Qualcomm module reports unknown symbols or CRC errors;
- the selected variant exposes only its intended KernelSU/Docker features.

If a basic phone function fails, restore stock boot before collecting further
feature results.

## Developer temporary boot / 开发者临时启动

Developers should test a repacked boot image before a persistent write:

```bash
adb reboot bootloader
fastboot getvar product
fastboot getvar current-slot
fastboot boot boot-diting-test.img
```

`fastboot boot` requires a complete boot image repacked from the matching stock
ramdisk; the raw kernel `Image` cannot be passed directly. A normal reboot
returns to the persistently installed boot image.

## Recovery / 恢复

If the phone stays at the first logo or boot animation:

1. hold the device key combination to return to Fastboot;
2. confirm the active slot;
3. flash the verified stock `boot.img` matching the installed ROM to that boot
   slot, or temporarily boot a known-good complete boot image;
4. reboot without relocking the bootloader;
5. collect early kernel, module-load, and Android init logs before another
   development attempt.

Do not change the active A/B slot as a generic rescue step. Firmware and
dynamic partitions on the other slot must belong to a consistent ROM build.
Restoring the matching stock boot image is the preferred recovery path.

The repository and release package never erase user data, flash firmware, or
lock the bootloader by themselves.
