# Redmi K50 Ultra Kernel — KernelSU-Next

[简体中文](README.zh-CN.md) | English

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
