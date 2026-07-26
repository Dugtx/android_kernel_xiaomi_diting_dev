# Building and KMI checks / 源码编译与 KMI 检查

This repository is the `common` kernel checkout, not a standalone compiler
SDK. Build it inside the matching ACK Build `14313284` workspace. Mixing a
newer compiler, another ACK tag, or artifacts from a different branch can
produce output that compiles but cannot load Xiaomi vendor modules.

本仓库只包含 `common` 内核源码，不是独立的编译 SDK。必须放入匹配的 ACK Build
`14313284` 工作区；不要混用其他 ACK、较新编译器或不同变体的构建产物。

## Fixed inputs / 固定输入

- ACK tag: `android12-5.10-2025-05_r6`
- ACK base: `fb24cf99ad973cd4c7c7fa375c6053f939ef3a89`
- Google build number: `14313284`
- Clang/LLD: `r416183b` (`12.0.5`)
- kernel release: `5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284`
- the selected branch's `.scmversion`
- the exact KernelSU-Next submodule revision on KernelSU branches

## Workspace layout / 工作区结构

```text
ack-build/
├── build/
├── common/                 # this repository / 本仓库
├── prebuilts/
└── prebuilts-master/
```

Initialize submodules after switching to `main` or `ksun-only`:

```bash
git submodule update --init --recursive
git -C KernelSU-Next rev-parse HEAD
```

## Branch profiles / 分支配置

| Branch | Build config | KernelSU-Next | Docker additions |
| --- | --- | --- | --- |
| `main` | `build.config.gki.aarch64.docker-network` | yes | yes |
| `docker-only` | `build.config.gki.aarch64.docker-network` | no | yes |
| `ksun-only` | `build.config.gki.aarch64` | yes | no |
| `baseline` | `build.config.gki.aarch64` | no | no |

Use a new `OUT_DIR` and `DIST_DIR` for every branch and commit.
每个分支和提交都应使用新的输出目录。

## Build / 编译

Example for `main` or `docker-only`:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-docker-$(git -C common rev-parse --short HEAD)" \
DIST_DIR="$PWD/out/diting-docker-$(git -C common rev-parse --short HEAD)/dist" \
build/build.sh -j"$(nproc)"
```

Example for `baseline` or `ksun-only`:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-$(git -C common rev-parse --short HEAD)" \
DIST_DIR="$PWD/out/diting-$(git -C common rev-parse --short HEAD)/dist" \
build/build.sh -j"$(nproc)"
```

Do not override the branch's vendor-compatible release identity.
不要覆盖分支中与厂商模块兼容的内核 release 标识。

## KMI compatibility gates / KMI 兼容门禁

First verify the embedded release:

```bash
strings "$DIST_DIR/Image" |
  grep -m1 '^Linux version 5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284'
```

Every feature build must be compared byte-for-byte with a clean build of the
`baseline` branch made from the same workspace:

```bash
cmp baseline/dist/vmlinux.symvers "$DIST_DIR/vmlinux.symvers"
cmp baseline/dist/abi.xml "$DIST_DIR/abi.xml"
cmp baseline/dist/abi_symbollist "$DIST_DIR/abi_symbollist"
```

An unexpected difference stops the release process. Investigate configuration,
genksyms input, exported symbols, and structure layout before booting the
output. Disabling KMI trimming or strict symbol-list checks is not a fix.

任何非预期差异都会阻止发布。应先检查配置、genksyms 输入、导出符号和结构布局，
不能通过关闭 trimming 或严格 symbol-list 检查继续。

Record the build artifacts:

```bash
sha256sum "$DIST_DIR"/{Image,Image.lz4,vmlinux.symvers,abi.xml,abi_symbollist}
```

An `Image` may include a build timestamp. ABI/KMI artifacts, the embedded
release, and the source revision are the compatibility identity; a changing
Image hash still requires explanation.

## Configuration checks / 配置检查

```bash
grep '^CONFIG_KSU=' "$OUT_DIR/common/.config"
grep -E '^(CONFIG_(PID_NS|USER_NS|IPC_NS|SYSVIPC|CGROUP_PIDS|CGROUP_DEVICE|CFS_BANDWIDTH|BLK_DEV_THROTTLING|BRIDGE_NETFILTER)=)' \
  "$OUT_DIR/common/.config"
```

Confirm that the selected branch contains only its intended capability set.
`docker-only` must not gain KernelSU, and `ksun-only` must not gain the Docker
profile.

## Before a pull request / 提交 PR 前

- run `git diff --check`;
- include the build profile and source revision;
- report all three ABI/KMI comparisons;
- describe any new Kconfig dependency or KABI adapter;
- keep boot images, modules, logs, and local paths outside Git.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for branch selection and the full
submission checklist.
