# Redmi K50 Ultra Kernel — KernelSU-Next + Docker

[简体中文](README.zh-CN.md) | English

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
