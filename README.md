<a id="top"></a>

# Redmi K50 Ultra 内核 / Kernel — KernelSU-Next + Docker

[简体中文](#简体中文) | [English](#english)

<a id="简体中文"></a>

## 简体中文

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）日常使用的内核，将
KernelSU-Next v3.3.0 与经过验收的 Docker 内核配置组合。项目基于 Google
Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。

该仓库不包含 SUSFS 或未公开实验功能。

### 能力

- KernelSU-Next 内核 Root；
- PID、IPC 和用户命名空间；
- PIDS 与 DEVICE cgroup 控制器；
- CPU shares、CFS 带宽及块 I/O 限速；
- OverlayFS 与容器文件系统依赖；
- veth、网桥 netfilter、连接跟踪、NAT 和 MASQUERADE；
- packet、Unix socket 和 netlink 诊断接口。

会改变小米敏感结构布局的功能使用受保护的 KABI 兼容实现。已验证源码提交：

```text
059228c8c44bfdd7808467b3db78e8e991ec359e
```

该版本的 `vmlinux.symvers`、`abi.xml` 和 `abi_symbollist` 与纯净基线逐字节一致。
临时设备启动通过，SELinux Enforcing、KernelSU Root、小米 QRTR 传输、Wi-Fi、
相机和音频正常。

### 编译

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-ksun-docker" \
DIST_DIR="$PWD/out/diting-ksun-docker/dist" \
build/build.sh -j"$(nproc)"
```

使用匹配的 ACK Build `14313284` 工作区和 Clang `r416183b`。不要替换固定的
KernelSU-Next 子模块，也不要覆盖厂商兼容的内核 release。

### 设备与运行时边界

该仓库只提供内核源码，不分发管理器 APK、Docker 用户态二进制、ROM、固件、
闭源模块或 boot 镜像。只能从未经修改的原厂 `boot.img` 重打包，并在持久刷写前
使用 `fastboot boot` 临时测试。

Android 上 Docker bridge 流量需要用户态动态设置策略路由；该策略属于运行时
部署，不应写入内核。

### 文档

- [编译与验收](wiki/Build-and-Validation.md)
- [架构与 KMI](wiki/Architecture-and-KMI.md)
- [Docker 与 KernelSU](wiki/Docker-and-KernelSU.md)
- [刷写与恢复](wiki/Flashing-and-Recovery.md)
- [第三方组件](THIRD_PARTY.md)
- [原始 ACK 指南](README.upstream.md)

### 协议与署名

内核源码、项目修改和 KernelSU-Next 内核组件使用 GPL-2.0-only 及兼容的文件级
SPDX 条款。详情见 [COPYING](COPYING)、[AUTHORS.md](AUTHORS.md)和
[THIRD_PARTY.md](THIRD_PARTY.md)。

维护者：Dugtx。上游贡献者保留其对应代码的作者身份。

[返回语言选择](#top)

---

<a id="english"></a>

## English

Daily-use kernel for the Redmi K50 Ultra (`diting`, Snapdragon 8+ Gen 1),
combining KernelSU-Next v3.3.0 with the validated Docker kernel profile. It is
based on ACK/GKI 5.10 from Google Build `14313284` and preserves the Xiaomi
vendor-module ABI required by HyperOS `OS2.0.211.0.VLFCNXM`.

SUSFS and unpublished experimental features are not present in this
repository.

## Capabilities

- KernelSU-Next kernel root support;
- PID, IPC and user namespaces;
- PIDS and DEVICE cgroup controllers;
- CPU shares, CFS bandwidth and block-I/O throttling;
- OverlayFS and container filesystem requirements;
- veth, bridge netfilter, conntrack, NAT and MASQUERADE;
- packet, Unix socket and netlink diagnostics.

Xiaomi-sensitive structure changes use guarded KABI compatibility
implementations. The validated source revision is:

```text
059228c8c44bfdd7808467b3db78e8e991ec359e
```

Its `vmlinux.symvers`, `abi.xml` and `abi_symbollist` were byte-identical to
the clean baseline. Temporary device boot passed with SELinux Enforcing,
KernelSU root, Xiaomi QRTR transports, Wi-Fi, camera and audio operational.

## Build

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-ksun-docker" \
DIST_DIR="$PWD/out/diting-ksun-docker/dist" \
build/build.sh -j"$(nproc)"
```

Build in the matching ACK Build `14313284` workspace with Clang `r416183b`.
Do not replace the pinned KernelSU-Next submodule or override the
vendor-compatible kernel release.

## Device and runtime boundary

The repository supplies kernel source only. It does not distribute manager
APKs, Docker userspace binaries, ROMs, firmware, proprietary modules or boot
images. Repack from an untouched stock `boot.img` and use `fastboot boot`
before persistent flashing.

Android networking requires runtime policy-routing rules for Docker bridge
traffic; that policy belongs in the userspace deployment, not the kernel.

## Documentation

- [Build and validation](wiki/Build-and-Validation.md)
- [Architecture and KMI](wiki/Architecture-and-KMI.md)
- [Docker and KernelSU](wiki/Docker-and-KernelSU.md)
- [Flashing and recovery](wiki/Flashing-and-Recovery.md)
- [Third-party components](THIRD_PARTY.md)
- [Original ACK guide](README.upstream.md)

## License and credits

Kernel sources, project modifications and the KernelSU-Next kernel component
use GPL-2.0-only and compatible per-file SPDX terms. See [COPYING](COPYING),
[AUTHORS.md](AUTHORS.md) and [THIRD_PARTY.md](THIRD_PARTY.md).

Maintainer: Dugtx. Upstream contributors retain authorship of their work.

[Back to language selection](#top)
