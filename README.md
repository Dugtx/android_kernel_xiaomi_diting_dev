# Redmi K50 Ultra 内核 / Kernel — KernelSU-Next

[简体中文](#简体中文) | [English](#english)

## 简体中文

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的 KernelSU-Next 内核，
基于 Google Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。

该版本只包含 KernelSU-Next，明确不包含 SUSFS、Docker 配置、管理器 APK、boot
镜像或小米闭源文件。

### 固定源码

```text
内核源码：03226eb9315f560d85869d1954de98d8682af2cf
KernelSU-Next：3b18216f71df189ab3d1b1ce0bdb21be1268e771（v3.3.0）
```

KernelSU-Next 通过官方仓库的 Git 子模块固定。内核已通过严格 ACK KMI 检查，
ABI/KMI 输出与纯净设备基线逐字节一致，并通过临时 `fastboot boot`；Android
完成启动、SELinux Enforcing、KernelSU Root 上下文及小米厂商模块正常。

### 编译

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-ksun" \
DIST_DIR="$PWD/out/diting-ksun/dist" \
build/build.sh -j"$(nproc)"
```

使用匹配的 ACK Build `14313284` 工作区和 Clang `r416183b`。内核 release 必须
与目标 ROM 保持兼容。

### 安全

只能使用未经修改的原厂 `boot.img` 重打包，持久刷写前先执行 `fastboot boot`，
保留经过校验的原厂镜像用于恢复，并且不要在启动组件被修改时重新锁定
Bootloader。

KernelSU 管理器属于独立用户态组件，本仓库不分发管理器。

### 协议与署名

内核源码及 KernelSU-Next 内核组件使用 GPL-2.0-only。详情见
[COPYING](COPYING)、[第三方来源](THIRD_PARTY.md)、子模块中的 `kernel/LICENSE`
和[原始 ACK 指南](README.upstream.md)。

维护者：Dugtx。上游贡献者保留其对应代码的作者身份。

---

## English

KernelSU-Next kernel for the Redmi K50 Ultra (`diting`, Snapdragon 8+ Gen 1),
based on ACK/GKI 5.10 from Google Build `14313284`. It preserves the Xiaomi
vendor-module ABI required by HyperOS `OS2.0.211.0.VLFCNXM`.

This variant contains KernelSU-Next only. It intentionally excludes SUSFS,
the Docker profile, manager APKs, boot images and proprietary Xiaomi files.

## Pinned source

```text
Kernel source: 03226eb9315f560d85869d1954de98d8682af2cf
KernelSU-Next: 3b18216f71df189ab3d1b1ce0bdb21be1268e771 (v3.3.0)
```

KernelSU-Next is recorded as a Git submodule from its official repository.
The kernel build passed the strict ACK KMI checks, and its ABI/KMI outputs were
byte-identical to the clean device baseline. Temporary `fastboot boot`
validation reached Android boot completion with SELinux Enforcing, a working
KernelSU root context and operational Xiaomi vendor modules.

## Build

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-ksun" \
DIST_DIR="$PWD/out/diting-ksun/dist" \
build/build.sh -j"$(nproc)"
```

Build in the matching ACK Build `14313284` workspace with Clang `r416183b`.
The embedded kernel release must remain compatible with the target ROM.

## Safety

Repack only from an untouched stock `boot.img`, test with `fastboot boot`
before persistent flashing, retain a verified stock image for recovery, and
never relock the bootloader with modified boot components.

KernelSU manager software is a separate userspace component and is not
distributed by this repository.

## License and credits

Kernel sources and the KernelSU-Next kernel component use GPL-2.0-only. See
[COPYING](COPYING), [third-party provenance](THIRD_PARTY.md), the submodule's
`kernel/LICENSE`, and the [original ACK guide](README.upstream.md).

Maintainer: Dugtx. Upstream contributors retain authorship of their work.
