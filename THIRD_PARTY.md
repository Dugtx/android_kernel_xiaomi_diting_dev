# Third-party components

| Component | Pinned source | Use | License |
| --- | --- | --- | --- |
| Linux kernel | Source contained in Android Common Kernel | Kernel foundation | GPL-2.0-only with declared exceptions |
| Android Common Kernel | Build `14313284`, base `fb24cf99ad973cd4c7c7fa375c6053f939ef3a89` | Android/GKI integration and ABI definitions | GPL-2.0-only and per-file SPDX terms |
| KernelSU-Next | `https://github.com/KernelSU-Next/KernelSU-Next.git`, commit `3b18216f71df189ab3d1b1ce0bdb21be1268e771` (`v3.3.0`) | Kernel root implementation | `/kernel`: GPL-2.0-only |
| Android Clang | `r416183b` | Build toolchain, not vendored | Apache-2.0 with LLVM exceptions |

After cloning, verify the pinned dependency:

```bash
git submodule update --init --recursive
git -C KernelSU-Next rev-parse HEAD
```

This repository does not redistribute Xiaomi ROMs, firmware, proprietary
modules, boot images, manager applications or toolchain binaries.
