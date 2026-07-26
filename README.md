# Redmi K50 Ultra Kernel — Docker

[简体中文](README.zh-CN.md) | English

Docker-capable Android kernel for the Redmi K50 Ultra (`diting`, Snapdragon
8+ Gen 1), based on ACK/GKI 5.10 from Google Build `14313284`. It preserves
the Xiaomi vendor-module ABI required by HyperOS `OS2.0.211.0.VLFCNXM`.

This repository contains no kernel root implementation. KernelSU, SUSFS,
Magisk, manager applications, boot images and container runtime binaries are
not included.

## Capabilities

The validated profile adds the namespace, IPC, cgroup, bridge firewalling,
NAT, virtual networking, CPU bandwidth and block-I/O controls required for
practical containers. Xiaomi-sensitive structure changes use guarded KABI
compatibility implementations.

Validated kernel source revision:

```text
ef369e1cc03c1f2f8030fa7ddd726efb0f59c29f
```

Its `vmlinux.symvers`, `abi.xml` and `abi_symbollist` were byte-identical to
the clean device baseline. Temporary `fastboot boot` validation reached
Android boot completion with SELinux Enforcing and working Xiaomi vendor
modules, Wi-Fi, camera and audio.

## Build

Check out this repository as `common` in the matching ACK Build `14313284`
workspace:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-docker" \
DIST_DIR="$PWD/out/diting-docker/dist" \
build/build.sh -j"$(nproc)"
```

Do not override `BUILD_NUMBER`; the source keeps the vendor-compatible kernel
release. See [Docker profile details](DOCKER_BASIC.md) before packaging.

## Boot image boundary

Normal ramdisk-only patching does not remove Docker features if the compiled
kernel `Image` remains unchanged. A patcher or flashing template that replaces
the kernel payload with stock or unrelated output removes these features.
Always compare the unpacked kernel payload and test with `fastboot boot` before
persistent flashing.

## License and credits

Kernel sources and project modifications use GPL-2.0-only and compatible
per-file SPDX terms. See [COPYING](COPYING),
[third-party provenance](THIRD_PARTY.md) and the
[original ACK guide](README.upstream.md).

Maintainer: Dugtx. Upstream contributors retain authorship of their work.
