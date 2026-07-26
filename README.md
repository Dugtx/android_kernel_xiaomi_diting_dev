# Redmi K50 Ultra 内核 / Kernel

[简体中文](#简体中文) | [English](#english) | [下载 / Downloads](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases) | [Wiki](wiki/Home.md)

## 简体中文

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的设备内核项目。它基于
Google ACK/GKI 5.10，为 HyperOS 保留小米厂商模块所需的内核 ABI，并提供可选的
KernelSU-Next 内核 Root 和 Docker/通用 Linux 内核能力。

### 主要能力

- KernelSU-Next 内核 Root，可由管理器在用户态控制授权；
- Docker 所需的命名空间、IPC、cgroup、OverlayFS、veth、网桥、NAT 和诊断接口；
- 内存、CPU、PIDS、DEVICE 和块 I/O 等资源控制基础；
- IPv6 NAT、macvlan、VXLAN 等容器网络能力；
- 保持 SELinux Enforcing，不以关闭 KMI 检查换取功能。

公开源码不包含 SUSFS、定位实验、管理器 APK、小米闭源模块或 Docker 用户态
二进制。

### 选择版本

所有版本都在同一个 [GitHub Release](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases)
页面发布。请按用途选择，不要在不同变体之间混用 `Image`。

| 版本 | 源码分支 | 适合谁 | 安装包名称 |
| --- | --- | --- | --- |
| KernelSU-Next + Docker | [`main`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/main) | 希望同时获得内核 Root 和容器能力的用户 | `*KernelSU-Next-Docker*.zip` |
| KernelSU-Next | [`ksun-only`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/ksun-only) | 只需要内核 Root，不运行 Docker | `*KernelSU-Next*.zip`，不含 `Docker` |
| Docker | [`docker-only`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/docker-only) | 已有兼容 Root 方案、只需要容器能力的高级用户 | `*Docker*.zip`，不含 `KernelSU-Next` |
| Baseline | [`baseline`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/baseline) | 内核开发、对照和故障排查 | `*Baseline*.zip` |

### 兼容性与风险

> **目前唯一支持的系统是 Redmi K50 Ultra 的 HyperOS
> `OS2.0.211.0.VLFCNXM`（Android 15）。** 其他 HyperOS、官改或类原生 ROM
> 即使能够启动，也不属于支持范围。

Docker 增量状态复用未启用的 cgroup 成员和 Android KABI 预留字段，以保持当前
厂商模块所依赖的结构布局。这里的“空槽位”是内核结构/KABI 槽位，**不是**手机
的 A/B 启动槽，也不代表内核能够跨 ROM 通用。

刷写内核始终存在无法开机、模块不兼容或数据不可访问的风险。必须保留与当前
ROM 完全匹配的原厂 `boot.img`、解锁的 Bootloader 和可用的 Fastboot 恢复路径。
不要在安装修改后的启动组件时重新锁定 Bootloader。

### 快速安装

1. 确认设备代号为 `diting`，系统版本为 `OS2.0.211.0.VLFCNXM`，Bootloader
   已解锁。
2. 从 [Releases](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases)
   下载所需 ZIP，并用同页 `SHA256SUMS` 校验文件。
3. 备份当前活动槽对应的原厂 `boot.img`。
4. 使用支持 AnyKernel3 的内核刷写工具或 Recovery 安装 ZIP。
5. 首次启动后检查 Android、网络、相机、音频、电话和 Root/容器功能；发现异常
   立即从 Fastboot 恢复原厂 `boot.img`。

AnyKernel3 包只替换活动 boot 槽中的内核 `Image`，保留现有 ramdisk。带
KernelSU-Next 的包检测到 Magisk 或其他非纯净 ramdisk 时会中止，以避免双 Root。
`v1.0.0-rc1` 的 AnyKernel3 安装与恢复流程尚未完成一次公开的真机演练，因此它
仍是面向有恢复能力用户的 Pre-release。详细步骤见[安装与恢复](wiki/Flashing-and-Recovery.md)。

### Docker 使用说明

Docker 变体提供**内核能力**。`main` 用户可安装独立项目
[docker-runtime-ksu-modle](https://github.com/Dugtx/docker-runtime-ksu-modle)
发布的 KernelSU 模块，获得 Docker Engine、Buildx、Compose、ext4 镜像管理、
开机服务与 WebUI。模块源码、构建工作流、第三方版本和哈希均在独立项目维护。

该模块依赖 KernelSU，因此不适用于不含 KernelSU 的 `docker-only` 分支；该分支
仍面向自行部署兼容 Root 与用户态运行时的高级用户。

日用建议保持 Android 原有布局，使用 cgroup v2 和隔离网络；需要内存、CPU、
devices、blkio 等完整资源限制时，再使用 Docker 私有挂载命名空间中的 cgroup
v1。Bridge 网络还需要用户态根据当前 Wi-Fi、移动数据或 VPN 动态设置策略路由。
参见 [KernelSU 与 Docker](wiki/Docker-and-KernelSU.md)。

### 从源码编译

将本仓库检出为 ACK Build `14313284` 工作区中的 `common`，使用 Clang/LLD
`r416183b`。KernelSU 分支还需要初始化固定的子模块：

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-main" \
DIST_DIR="$PWD/out/diting-main/dist" \
build/build.sh -j"$(nproc)"
```

`main` 和 `docker-only` 使用 `build.config.gki.aarch64.docker-network`；
`baseline` 和 `ksun-only` 使用 `build.config.gki.aarch64`。完整目录结构和检查命令
见[源码编译与 KMI 检查](wiki/Build-and-Validation.md)。

### KMI 硬约束

小米的显示、相机、音频、网络和 QRTR 等驱动主要来自 vendor 模块。一个能够
编译成功的内核仍可能因符号 CRC、`vermagic` 或冻结结构布局变化而卡在开机动画。
所有功能改动都必须保持目标 ROM 所需的：

- `UTS_RELEASE` 与模块 `vermagic`；
- 导出的 KMI 符号集合及其 CRC；
- 厂商模块使用的敏感结构布局；
- 严格 KMI symbol-list 与 trimming 检查。

不得用关闭 `TRIM_NONLISTED_KMI` 或严格模式掩盖兼容性问题。详细设计见
[架构与 KMI](wiki/Architecture-and-KMI.md)。

### 参与贡献

四个长期分支代表不同的发布产品，不是等待合并到 `main` 的临时功能分支。
提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)，选择正确的目标分支，并附上
构建配置、ABI/KMI 比较和适用范围。不要提交 boot 镜像、ROM、APK、厂商模块、
设备日志或凭据。

### 文档与协议

- [Wiki 导航](wiki/Home.md)
- [安装与恢复](wiki/Flashing-and-Recovery.md)
- [源码编译与 KMI 检查](wiki/Build-and-Validation.md)
- [架构与 KMI](wiki/Architecture-and-KMI.md)
- [KernelSU 与 Docker](wiki/Docker-and-KernelSU.md)
- [CI 与发布工作流](wiki/CI-and-Releases.md)
- [安全与发布](wiki/Security-and-Publication.md)
- [第三方组件](THIRD_PARTY.md)
- [原始 ACK 指南](README.upstream.md)

内核源码、项目修改和 KernelSU-Next 内核组件使用 GPL-2.0-only 及兼容的文件级
SPDX 条款。维护者：Dugtx；上游贡献者保留其对应代码的作者身份。

---

## English

Device kernel project for the Redmi K50 Ultra (`diting`, Snapdragon 8+ Gen 1).
It is based on Google ACK/GKI 5.10, preserves the kernel ABI required by
Xiaomi vendor modules on HyperOS, and provides optional KernelSU-Next root and
Docker/general-purpose Linux kernel capabilities.

### Highlights

- KernelSU-Next kernel root with userspace authorization control;
- namespaces, IPC, cgroups, OverlayFS, veth, bridges, NAT, and diagnostics for Docker;
- memory, CPU, PIDS, DEVICE, and block-I/O resource-control foundations;
- IPv6 NAT, macvlan, and VXLAN container networking;
- SELinux Enforcing without bypassing strict KMI checks.

Public source contains no SUSFS, location experiments, manager APKs,
proprietary Xiaomi modules, or Docker userspace binaries.

### Choose a variant

All variants are published on one [GitHub Releases](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases)
page. Do not mix kernel Images between variants.

| Variant | Source branch | Intended use | Package name |
| --- | --- | --- | --- |
| KernelSU-Next + Docker | [`main`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/main) | Kernel root and container support | `*KernelSU-Next-Docker*.zip` |
| KernelSU-Next | [`ksun-only`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/ksun-only) | Kernel root without Docker additions | `*KernelSU-Next*.zip`, without `Docker` |
| Docker | [`docker-only`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/docker-only) | Container support with a separate compatible root solution | `*Docker*.zip`, without `KernelSU-Next` |
| Baseline | [`baseline`](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/tree/baseline) | Development, comparison, and recovery diagnosis | `*Baseline*.zip` |

### Compatibility and risk

> **The only supported system is HyperOS `OS2.0.211.0.VLFCNXM` (Android 15)
> on the Redmi K50 Ultra.** Other HyperOS, modified-stock, and AOSP-derived ROMs
> are outside the support scope even if they happen to boot.

Docker state reuses inactive cgroup members and Android KABI reserve fields to
preserve layouts consumed by current vendor modules. These “spare slots” are
kernel structure/KABI slots, **not** the phone's A/B boot slots, and do not
make this a cross-ROM universal kernel.

Flashing a kernel can cause boot failure, module incompatibility, or
inaccessible data. Keep the untouched stock `boot.img` matching the installed
ROM, an unlocked bootloader, and a working Fastboot recovery path. Never
relock the bootloader while modified boot components are installed.

### Quick install

1. Confirm the device codename is `diting`, the ROM is
   `OS2.0.211.0.VLFCNXM`, and the bootloader is unlocked.
2. Download the required ZIP from [Releases](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases)
   and verify it against `SHA256SUMS`.
3. Back up the stock `boot.img` for the current active slot.
4. Install the ZIP with an AnyKernel3-compatible kernel flasher or recovery.
5. After the first boot, check Android, networking, camera, audio, telephony,
   and root/container features. Restore the stock boot through Fastboot if
   anything is abnormal.

The AnyKernel3 package replaces only the kernel `Image` in the active boot
slot and preserves the existing ramdisk. KernelSU-Next packages abort when a
Magisk-patched or otherwise non-stock ramdisk is detected to avoid dual root.
The AnyKernel3 install-and-recovery path in `v1.0.0-rc1` has not yet completed
a public on-device rehearsal, so it remains a Pre-release for users with a
working recovery path. See [Flashing and recovery](wiki/Flashing-and-Recovery.md).

### Using Docker

Docker variants provide the required **kernel capabilities**. Users of `main`
can install the KernelSU module released by the separate
[docker-runtime-ksu-modle](https://github.com/Dugtx/docker-runtime-ksu-modle)
project to obtain Docker Engine, Buildx, Compose, ext4 image management, an
autostart service, and a WebUI. Its source, build workflows, third-party pins,
and checksums are maintained in that project.

The module requires KernelSU and therefore is not usable on the `docker-only`
branch by itself. That branch remains intended for advanced users who provide
a separate compatible root and userspace runtime.

For daily use, keep Android's cgroup layout and use cgroup v2 with isolated
networking. Switch to a Docker-private cgroup v1 mount namespace only when
memory, CPU, devices, and blkio limits are required. Bridge networking also
needs userspace policy routing that follows the active Wi-Fi, mobile-data, or
VPN uplink. See [KernelSU and Docker](wiki/Docker-and-KernelSU.md).

### Build from source

Check out this repository as `common` in the ACK Build `14313284` workspace
and use Clang/LLD `r416183b`. Initialize the pinned submodule on KernelSU
branches:

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-main" \
DIST_DIR="$PWD/out/diting-main/dist" \
build/build.sh -j"$(nproc)"
```

Use `build.config.gki.aarch64.docker-network` on `main` and `docker-only`, and
`build.config.gki.aarch64` on `baseline` and `ksun-only`. See
[Building and KMI checks](wiki/Build-and-Validation.md) for the complete
workspace and gate sequence.

### KMI contract

Display, camera, audio, networking, QRTR, and other Xiaomi hardware support is
largely supplied by vendor modules. A kernel that compiles can still stop at
the boot animation when a symbol CRC, `vermagic`, or frozen layout changes.
Every feature change must preserve:

- the target `UTS_RELEASE` and module `vermagic`;
- exported KMI symbols and their CRCs;
- sensitive layouts consumed by vendor modules;
- strict symbol-list and KMI trimming checks.

Do not hide compatibility failures by disabling `TRIM_NONLISTED_KMI` or strict
mode. See [Architecture and KMI](wiki/Architecture-and-KMI.md).

### Contributing

The four long-lived branches are separate release products, not temporary
feature branches waiting to be merged into `main`. Read
[CONTRIBUTING.md](CONTRIBUTING.md), target the correct branch, and include the
build profile, ABI/KMI comparison, and intended scope with a change. Do not
commit boot images, ROMs, APKs, proprietary modules, device logs, or
credentials.

### Documentation and license

- [Wiki home](wiki/Home.md)
- [Flashing and recovery](wiki/Flashing-and-Recovery.md)
- [Building and KMI checks](wiki/Build-and-Validation.md)
- [Architecture and KMI](wiki/Architecture-and-KMI.md)
- [KernelSU and Docker](wiki/Docker-and-KernelSU.md)
- [CI and release workflows](wiki/CI-and-Releases.md)
- [Security and publication](wiki/Security-and-Publication.md)
- [Third-party components](THIRD_PARTY.md)
- [Original ACK guide](README.upstream.md)

Kernel sources, project changes, and the KernelSU-Next kernel component use
GPL-2.0-only and compatible per-file SPDX terms. Maintainer: Dugtx; upstream
contributors retain authorship of their work.
