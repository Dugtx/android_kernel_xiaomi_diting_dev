# Redmi K50 Ultra 内核 / Kernel — 纯净基线 / Baseline

[简体中文](#简体中文) | [English](#english)

## 简体中文

这是 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的纯净设备基线。源码来自
Google Build `14313284` 对应的 Android Common Kernel 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 厂商模块所需的内核版本标识与 ABI。

### 范围

该仓库只包含经过验证的 ACK/GKI 基线和小米兼容的 SCM 版本标识，明确不包含
KernelSU、SUSFS、Docker 配置、管理器应用、boot 镜像、固件或小米闭源模块。

已验证源码提交：

```text
db116cdd6e203d7d9b92c2fb9c2d2569b2406c37
```

### 编译

将仓库检出为匹配 ACK Build `14313284` 工作区中的 `common`，并使用 Clang
`r416183b`：

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-baseline" \
DIST_DIR="$PWD/out/diting-baseline/dist" \
build/build.sh -j"$(nproc)"
```

内核 release 必须保持为：

```text
5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284
```

### 设备安全

只能使用与目标 ROM 匹配、未经修改的原厂 `boot.img` 重打包。持久刷写前先用
`fastboot boot` 临时测试，保留校验过的原厂镜像用于恢复，并且不要在启动组件
被修改时重新锁定 Bootloader。

### 协议与署名

Linux 和 Android Common Kernel 源码遵循 GPL-2.0-only 及源码文件中已有的兼容
SPDX 条款。详情见 [COPYING](COPYING)、[第三方来源](THIRD_PARTY.md)和
[原始 ACK 指南](README.upstream.md)。

维护者：Dugtx。上游贡献者保留其对应代码的作者身份。

---

## English

Clean device baseline for the Redmi K50 Ultra (`diting`, Snapdragon 8+ Gen 1).
It is based on Android Common Kernel 5.10 from Google Build `14313284` and
preserves the kernel release and ABI required by HyperOS
`OS2.0.211.0.VLFCNXM` vendor modules.

## Scope

This repository contains only the verified ACK/GKI baseline and the
Xiaomi-compatible SCM release identity. It intentionally contains no
KernelSU, SUSFS, Docker profile, manager application, boot image, firmware or
proprietary Xiaomi module.

Validated source revision:

```text
db116cdd6e203d7d9b92c2fb9c2d2569b2406c37
```

## Build

Check out this repository as `common` in the matching ACK Build `14313284`
workspace and use Clang `r416183b`:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-baseline" \
DIST_DIR="$PWD/out/diting-baseline/dist" \
build/build.sh -j"$(nproc)"
```

The embedded kernel release must remain:

```text
5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284
```

## Device safety

Repack only from an untouched stock `boot.img` matching the target ROM. Test
new output with `fastboot boot` before any persistent flash, retain a verified
stock image for recovery, and never relock the bootloader with modified boot
components.

## License and credits

The Linux kernel and Android Common Kernel sources are distributed under
GPL-2.0-only and the compatible per-file SPDX terms already present in the
tree. See [COPYING](COPYING), [third-party provenance](THIRD_PARTY.md) and the
[original ACK guide](README.upstream.md).

Maintainer: Dugtx. Upstream contributors retain authorship of their work.
