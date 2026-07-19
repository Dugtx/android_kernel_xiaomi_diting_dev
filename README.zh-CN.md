# Redmi K50 Ultra 内核

简体中文 | [English](README.md)

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的 Android 内核项目。
项目以 Google Build `14313284` 对应的 Android Common Kernel 5.10 为基础，
并保持 HyperOS `OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI 兼容性。

仓库只保留三条可复现源码线：

| 分支 | 用途 |
| --- | --- |
| `baseline/ack-14313284` | 纯净 ACK 源码快照及小米兼容的内核版本标识 |
| `release/ksun-only` | 基线加 KernelSU-Next v3.3.0 |
| `release/ksun-docker` | KernelSU-Next 加已验收的容器内核配置 |
| `main` | 项目文档及当前 `release/ksun-docker` 源码 |

## 项目范围

Docker 配置补充了实用容器所需的命名空间、cgroup 控制器、IPC、网桥防火墙、
CFS 带宽控制、块 I/O 限速及网络驱动。KABI 兼容层用于在启用这些能力时，
继续兼容小米闭源的树外厂商模块。

本公开源码树明确不包含：

- 小米固件、ROM、boot 镜像或闭源厂商模块
- KernelSU 管理器 APK 或 Docker 用户态二进制
- 未公开的实验性功能分支
- 开发机文件系统、网络文件共享、USB 外设和 TCP 调优扩展

## 编译

使用精确的 ACK Build `14313284` 环境与 Clang `r416183b`。假设本仓库在
ACK 构建根目录中检出为 `common`：

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-ksun-docker" \
DIST_DIR="$PWD/out/diting-ksun-docker/dist" \
build/build.sh -j"$(nproc)"
```

基线与 KSUN-only 分支使用 `common/build.config.gki.aarch64`。最终镜像内嵌
版本必须为：

```text
5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284
```

打包和测试前请完整阅读[编译与验收](wiki/Build-and-Validation.md)。

## 安全提示

该设备使用 A/B 启动槽、Android Verified Boot 和小米闭源模块。新内核必须
先通过 `fastboot boot` 临时启动测试。不要在使用修改镜像时重新锁定
Bootloader，并始终保存经过校验的原厂 `boot.img` 用于恢复。

## 文档

- [项目 Wiki](wiki/Home.md)
- [架构与 KMI](wiki/Architecture-and-KMI.md)
- [KernelSU 与 Docker 配置](wiki/Docker-and-KernelSU.md)
- [刷写与恢复](wiki/Flashing-and-Recovery.md)
- [第三方组件](THIRD_PARTY.md)
- [原始 ACK 补丁指南](README.upstream.md)

## 协议与署名

Linux 内核源码及本项目的内核修改按照 GPL-2.0-only 分发；系统调用 UAPI
例外沿用上游源码中的声明。详情见 [COPYING](COPYING) 和各文件的 SPDX 标识。

项目维护者：**Dugtx**。署名信息见 [AUTHORS.md](AUTHORS.md)。
