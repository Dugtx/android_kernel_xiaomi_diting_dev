# Build and validation / 编译与验收

## 1. Fixed inputs / 固定输入

Use all of the following together:

- source base `android12-5.10-2025-05_r6`
- ACK base commit `fb24cf99ad973cd4c7c7fa375c6053f939ef3a89`
- Google build number `14313284`
- Clang/LLD `r416183b` (`12.0.5`)
- the branch's pinned `.scmversion`
- the exact KernelSU-Next submodule revision on KSUN branches

不要把较新的 Clang、任意 ACK 分支或不同 KernelSU 提交混合进一次发布构建。

## 2. Expected layout / 目录结构

The kernel checkout is named `common` beside the ACK build tools:

```text
ack-build/
├── build/
├── common/                 # this repository
├── prebuilts/
└── prebuilts-master/
```

Initialize the submodule when the selected branch contains it:

```bash
git submodule update --init --recursive
```

## 3. Clean branch builds / 分支编译

Use a new output directory for every branch and commit.

Baseline or KSUN-only:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-$(git -C common rev-parse --short HEAD)" \
DIST_DIR="$PWD/out/diting-$(git -C common rev-parse --short HEAD)/dist" \
build/build.sh -j"$(nproc)"
```

KSUN plus Docker:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-docker-$(git -C common rev-parse --short HEAD)" \
DIST_DIR="$PWD/out/diting-docker-$(git -C common rev-parse --short HEAD)/dist" \
build/build.sh -j"$(nproc)"
```

## 4. Required gates / 必须通过的门禁

Check the embedded kernel release:

```bash
strings "$DIST_DIR/Image" |
  grep -m1 '^Linux version 5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284'
```

For every feature branch, compare these files byte-for-byte with the accepted
baseline build:

```bash
cmp baseline/dist/vmlinux.symvers "$DIST_DIR/vmlinux.symvers"
cmp baseline/dist/abi.xml "$DIST_DIR/abi.xml"
cmp baseline/dist/abi_symbollist "$DIST_DIR/abi_symbollist"
```

Any difference must be investigated before boot testing. Disabling KMI
trimming is not a substitute for preserving Xiaomi vendor-module compatibility.

Also record:

```bash
sha256sum "$DIST_DIR"/{Image,Image.lz4,vmlinux.symvers,abi.xml,abi_symbollist}
```

Kernel binaries include a build timestamp unless the builder explicitly fixes
all Kbuild timestamp inputs. Therefore two otherwise equivalent builds may
have different `Image` hashes; ABI/KMI artifacts and the embedded release are
the compatibility gates used by this project.

## 5. Configuration checks / 配置检查

```bash
grep '^CONFIG_KSU=' "$OUT_DIR/common/.config"
grep -E '^(CONFIG_(PID_NS|USER_NS|IPC_NS|SYSVIPC|CGROUP_PIDS|CGROUP_DEVICE|CFS_BANDWIDTH|BLK_DEV_THROTTLING|BRIDGE_NETFILTER)=)' \
  "$OUT_DIR/common/.config"
```

The actual output subdirectory follows `KERNEL_DIR`; adjust the path if the
checkout has another name.
