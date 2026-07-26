# Redmi K50 Ultra 内核 / Kernel

[简体中文](#简体中文) | [English](#english) | [下载 / Downloads](https://github.com/Dugtx/android_kernel_xiaomi_diting/releases)

## 简体中文

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的统一内核源码仓库。
项目基于 Google Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。

默认 `main` 分支组合 KernelSU-Next v3.3.0 与经过验收的 Docker 内核能力。
纯净基线和单功能版本保留为长期分支，便于协作、比较和独立构建：

| 分支 | KernelSU-Next | Docker 内核能力 | 用途 |
| --- | --- | --- | --- |
| [`main`](../../tree/main) | 是 | 是 | 推荐完整版本 |
| [`baseline`](../../tree/baseline) | 否 | 否 | 纯净 ACK/GKI 对照基线 |
| [`docker-only`](../../tree/docker-only) | 否 | 是 | 与其他 Root 方案组合的高级用途 |
| [`ksun-only`](../../tree/ksun-only) | 是 | 否 | 只需要内核 Root 的用户 |

> **兼容性边界：** 当前只针对 HyperOS `OS2.0.211.0.VLFCNXM` 完成适配和
> 真机验收。Docker 相关的 PIDS、DEVICE 等增量状态复用原内核未启用的
> cgroup 槽位和 Android KABI 预留槽位，以避免扩大冻结结构。这里的“空槽位”
> 不是手机 A/B 启动槽，也不表示兼容其他 ROM。

公开分支均不包含 SUSFS 或定位实验代码。

### `main` 分支能力

- KernelSU-Next 内核 Root；
- PID、IPC 和用户命名空间；
- PIDS 与 DEVICE cgroup 控制器；
- CPU shares、CFS 带宽及块 I/O 限速；
- OverlayFS 与容器文件系统依赖；
- veth、网桥 netfilter、连接跟踪、NAT 和 MASQUERADE；
- packet、Unix socket 和 netlink 诊断接口。

会改变小米敏感结构布局的功能使用受保护的 KABI 兼容实现。已验收内核源码
版本的 `vmlinux.symvers`、`abi.xml` 和 `abi_symbollist` 与纯净基线逐字节一致。
临时设备启动通过，SELinux Enforcing、KernelSU Root、小米 QRTR、Wi-Fi、相机、
音频及 Docker 核心能力正常。

### 编译

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-main" \
DIST_DIR="$PWD/out/diting-main/dist" \
build/build.sh -j"$(nproc)"
```

使用匹配的 ACK Build `14313284` 工作区和 Clang `r416183b`。切换到其他长期
分支后，应使用该分支 README 指定的构建配置。不要覆盖厂商兼容的内核 release。

### 发布方式

一个版本使用一张 GitHub Release 页面，提供四个明确命名的 AnyKernel3 包。
每个包在发布清单中记录对应源码分支、源码 tag、提交和 SHA-256；不能在不同
变体之间混用内核镜像或根据 ZIP 名称猜测功能。

### 设备与运行时边界

只能从匹配目标 ROM 的纯净原厂 `boot.img` 重打包，并在持久刷写前使用
`fastboot boot` 临时测试。Android 上 Docker bridge 所需的动态策略路由属于
用户态运行模块，不应固化进内核。

### 文档与协议

- [编译与验收](wiki/Build-and-Validation.md)
- [架构与 KMI](wiki/Architecture-and-KMI.md)
- [Docker 与 KernelSU](wiki/Docker-and-KernelSU.md)
- [刷写与恢复](wiki/Flashing-and-Recovery.md)
- [第三方组件](THIRD_PARTY.md)
- [原始 ACK 指南](README.upstream.md)

内核源码、项目修改和 KernelSU-Next 内核组件使用 GPL-2.0-only 及兼容的文件级
SPDX 条款。维护者：Dugtx；上游贡献者保留其对应代码的作者身份。

---

## English

Unified kernel source repository for the Redmi K50 Ultra (`diting`, Snapdragon
8+ Gen 1). It is based on ACK/GKI 5.10 from Google Build `14313284` and
preserves the Xiaomi vendor-module ABI required by HyperOS
`OS2.0.211.0.VLFCNXM`.

The default `main` branch combines KernelSU-Next v3.3.0 with the validated
Docker kernel capabilities. Long-lived baseline and single-feature branches
remain available for collaboration, comparison and independent builds:

| Branch | KernelSU-Next | Docker kernel support | Purpose |
| --- | --- | --- | --- |
| [`main`](../../tree/main) | Yes | Yes | Recommended complete variant |
| [`baseline`](../../tree/baseline) | No | No | Clean ACK/GKI reference |
| [`docker-only`](../../tree/docker-only) | No | Yes | Advanced use with a separate root solution |
| [`ksun-only`](../../tree/ksun-only) | Yes | No | Kernel root without Docker additions |

> **Compatibility boundary:** only HyperOS `OS2.0.211.0.VLFCNXM` has been
> adapted and validated on-device. Docker-related PIDS, DEVICE and other state
> reuse inactive cgroup slots and Android KABI reserve fields to avoid growing
> frozen structures. These spare slots are not A/B boot slots and do not imply
> compatibility with another ROM.

Public branches contain neither SUSFS nor location experiments.

### `main` capabilities

- KernelSU-Next kernel root support;
- PID, IPC and user namespaces;
- PIDS and DEVICE cgroup controllers;
- CPU shares, CFS bandwidth and block-I/O throttling;
- OverlayFS and container filesystem requirements;
- veth, bridge netfilter, conntrack, NAT and MASQUERADE;
- packet, Unix socket and netlink diagnostics.

Xiaomi-sensitive structure changes use guarded KABI compatibility
implementations. The accepted kernel revision retained byte-identical
`vmlinux.symvers`, `abi.xml` and `abi_symbollist` compared with the clean
baseline. Temporary boot validation passed with SELinux Enforcing, KernelSU
root, Xiaomi QRTR, Wi-Fi, camera, audio and Docker core functionality working.

### Build

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-main" \
DIST_DIR="$PWD/out/diting-main/dist" \
build/build.sh -j"$(nproc)"
```

Use the matching ACK Build `14313284` workspace and Clang `r416183b`. After
switching to another long-lived branch, follow that branch's README and build
profile. Do not override the vendor-compatible kernel release.

### Releases

One project version uses one GitHub Release page containing four clearly named
AnyKernel3 packages. The release manifest maps every package to its source
branch, source tag, commit and SHA-256. Never mix kernel images between
variants or infer capabilities from an ambiguous filename.

### Device and runtime boundary

Repack only from an untouched stock `boot.img` matching the target ROM and use
`fastboot boot` before persistent flashing. Dynamic Android policy routing for
Docker bridge traffic belongs in the userspace runtime module, not the kernel.

### Documentation and licensing

- [Build and validation](wiki/Build-and-Validation.md)
- [Architecture and KMI](wiki/Architecture-and-KMI.md)
- [Docker and KernelSU](wiki/Docker-and-KernelSU.md)
- [Flashing and recovery](wiki/Flashing-and-Recovery.md)
- [Third-party components](THIRD_PARTY.md)
- [Original ACK guide](README.upstream.md)

Kernel sources, project modifications and the KernelSU-Next kernel component
use GPL-2.0-only and compatible per-file SPDX terms. Maintainer: Dugtx;
upstream contributors retain authorship of their work.
