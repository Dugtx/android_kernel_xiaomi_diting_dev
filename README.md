# Redmi K50 Ultra Kernel — Baseline

[简体中文](README.zh-CN.md) | English

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
