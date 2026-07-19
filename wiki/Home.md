# Redmi K50 Ultra kernel wiki

This wiki describes the public, device-focused source tree. Chinese and English
are presented together where operational details matter.

## Reading order / 阅读顺序

1. [Build and validation / 编译与验收](Build-and-Validation.md)
2. [Architecture and KMI / 架构与 KMI](Architecture-and-KMI.md)
3. [KernelSU and Docker / KernelSU 与 Docker](Docker-and-KernelSU.md)
4. [Flashing and recovery / 刷写与恢复](Flashing-and-Recovery.md)
5. [Security and publication / 安全与发布](Security-and-Publication.md)

## Supported target / 支持目标

- Device / 设备：Redmi K50 Ultra
- Codename / 代号：`diting`
- SoC：Qualcomm Snapdragon 8+ Gen 1 (`SM8475`)
- Tested ROM family / 目标系统：HyperOS 2, Android 15
- Reference build / 参考版本：`OS2.0.211.0.VLFCNXM`
- Kernel base / 内核基础：ACK 5.10.236, Android 12-5.10 GKI
- Page size / 页大小：4 KiB

Compatibility with another ROM, firmware release or device is not implied.
其他 ROM、固件或设备必须重新完成 ABI、启动和硬件功能验收。
