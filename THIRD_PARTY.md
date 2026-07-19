# Third-party components

This file records dependencies that are present in, or required to build, the
repository. It is not a replacement for each component's license text.

| Component | Source/provenance | How it is used | License |
| --- | --- | --- | --- |
| Linux kernel | Upstream Linux source contained in ACK | Kernel foundation | GPL-2.0-only with declared exceptions |
| Android Common Kernel | `android12-5.10-2025-05_r6`, base `fb24cf99ad973cd4c7c7fa375c6053f939ef3a89` | Android/GKI integration and ABI definitions | GPL-2.0-only and per-file SPDX licenses |
| KernelSU-Next | `https://github.com/KernelSU-Next/KernelSU-Next.git`, pinned submodule commit `3b18216f71df189ab3d1b1ce0bdb21be1268e771` (`v3.3.0`) | Kernel root implementation on KSUN branches | GPL-2.0 |
| Android Clang | `r416183b` from ACK Build `14313284` | Compiler and linker; not vendored in this repository | Apache-2.0 with LLVM exceptions, as distributed upstream |

## Deliberately not vendored

The repository does not redistribute Xiaomi ROM images, firmware, proprietary
kernel modules, Magisk tools, manager APKs, Docker binaries or Android
platform-tools. A user must obtain any required proprietary stock image from
an authorized source and verify that it matches the target device and ROM.

## Submodule verification

After cloning:

```bash
git submodule update --init --recursive
git -C KernelSU-Next rev-parse HEAD
git -C KernelSU-Next describe --tags --always
```

The first command must resolve the exact commit recorded above. Do not replace
the pinned submodule with an installation script fetched at build time.
