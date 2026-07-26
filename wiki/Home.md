# Redmi K50 Ultra kernel wiki / 内核 Wiki

This wiki covers the public Redmi K50 Ultra (`diting`) kernel, its four source
variants, installation boundaries, Docker requirements, and KMI-safe
development workflow.

本 Wiki 面向使用内核的普通用户和参与源码开发的贡献者。当前支持范围仅为
Redmi K50 Ultra 的 HyperOS `OS2.0.211.0.VLFCNXM`（Android 15）。

## User guide / 用户指南

1. [Project overview and package chooser / 项目介绍与选包](../README.md)
2. [Flashing and recovery / 安装与恢复](Flashing-and-Recovery.md)
3. [KernelSU and Docker / KernelSU 与 Docker](Docker-and-KernelSU.md)
4. [GitHub Releases / 下载页面](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases)

Start here if you want to decide which package to download, understand what
AnyKernel3 changes, prepare a stock boot fallback, or run Docker userspace.

如果你的目标是选包、刷入、恢复或运行 Docker，从本节开始阅读。

## Developer guide / 开发者指南

1. [Building and KMI checks / 源码编译与 KMI 检查](Build-and-Validation.md)
2. [Architecture and KMI / 架构与 KMI](Architecture-and-KMI.md)
3. [Contributing / 参与贡献](../CONTRIBUTING.md)
4. [Security and publication / 安全与发布](Security-and-Publication.md)
5. [Third-party components / 第三方组件](../THIRD_PARTY.md)

Developers should choose the target branch before changing configuration or
vendor-facing code. A successful compile does not prove Xiaomi module
compatibility; the KMI comparison is mandatory.

开发者应先确定目标分支，再修改配置或厂商接口。能够编译不代表能够兼容小米
模块，KMI 比较属于强制门禁。

## Supported target / 支持目标

| Item | Value |
| --- | --- |
| Device / 设备 | Redmi K50 Ultra |
| Codename / 代号 | `diting` |
| SoC | Qualcomm Snapdragon 8+ Gen 1 (`SM8475`) |
| Supported ROM / 支持系统 | HyperOS `OS2.0.211.0.VLFCNXM`, Android 15 |
| Kernel base / 内核基础 | ACK 5.10.236, Android 12-5.10 GKI |
| Page size / 页大小 | 4 KiB |

Compatibility with another ROM, firmware release, or device is not implied.
The cgroup/KABI “spare slots” used by Docker features are not A/B boot slots.

项目不承诺兼容其他 ROM、固件或设备。Docker 功能使用的 cgroup/KABI“空槽位”
不是手机 A/B 启动槽。
