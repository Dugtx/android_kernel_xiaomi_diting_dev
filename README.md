# Redmi K50 Ultra Kernel

[简体中文](README.zh-CN.md) | English

Device-focused Android kernel development for the Redmi K50 Ultra
(`diting`, Snapdragon 8+ Gen 1). The project starts from the Android Common
Kernel 5.10 source used by Google build `14313284` and preserves the Xiaomi
vendor-module ABI required by HyperOS `OS2.0.211.0.VLFCNXM`.

The repository is intentionally limited to three reproducible source lines:

| Branch | Purpose |
| --- | --- |
| `baseline/ack-14313284` | Clean ACK source snapshot and Xiaomi-compatible release identity |
| `release/ksun-only` | Baseline plus KernelSU-Next v3.3.0 |
| `release/ksun-docker` | KernelSU-Next plus the validated container kernel profile |
| `main` | Documentation and the current `release/ksun-docker` source |

## Project scope

The Docker profile adds the namespaces, cgroup controllers, IPC, bridge
firewalling, CFS bandwidth control, block-I/O throttling and network drivers
needed for practical containers. KABI compatibility shims keep Xiaomi's
out-of-tree vendor modules usable while these features are enabled.

This public tree does **not** contain:

- Xiaomi firmware, ROM files, boot images or proprietary vendor modules
- KernelSU manager APKs or container runtime binaries
- unpublished experimental feature branches
- development-machine filesystem, file-sharing, USB-peripheral or TCP-tuning
  extensions

## Build

Use the exact ACK build `14313284` environment and Clang `r416183b`. From a
build root where this repository is checked out as `common`:

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

Use `common/build.config.gki.aarch64` for the baseline and KSUN-only branches.
The embedded release must be:

```text
5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284
```

See [Build and validation](wiki/Build-and-Validation.md) before packaging or
testing any result.

## Safety

The target uses A/B boot slots, Android Verified Boot and proprietary
Xiaomi modules. Test a newly repacked image with `fastboot boot` first. Never
lock the bootloader with a modified image, and keep a verified stock
`boot.img` available for recovery.

## Documentation

- [Project wiki](wiki/Home.md)
- [Architecture and KMI](wiki/Architecture-and-KMI.md)
- [KernelSU and Docker profile](wiki/Docker-and-KernelSU.md)
- [Flashing and recovery](wiki/Flashing-and-Recovery.md)
- [Third-party components](THIRD_PARTY.md)
- [Original ACK patch guide](README.upstream.md)

## License and credits

The Linux kernel source and project kernel modifications are distributed under
GPL-2.0-only; syscall UAPI exceptions remain as declared by the upstream tree.
See [COPYING](COPYING) and the SPDX identifiers in individual files.

Project maintainer: **Dugtx**. See [AUTHORS.md](AUTHORS.md) for attribution.
