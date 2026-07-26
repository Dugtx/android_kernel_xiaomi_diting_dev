# Docker kernel profile

Author: Dugtx

This profile extends the pinned Android 12 5.10 GKI configuration without
editing `gki_defconfig`. Its release entry point is:

```text
build.config.gki.aarch64.docker-network
```

The configuration chain deliberately adds one capability group at a time:

```text
docker-basic
  -> docker-cgroup-pids-compat
  -> docker-cgroups-compat
  -> docker-pid-ns
  -> docker-netfilter
  -> docker-ipc
  -> docker-user-ns
  -> docker-resources-cfs-probe
  -> docker-blk-throttle
  -> docker-network
```

The compatibility profiles retain Xiaomi's accepted symbol CRCs and relevant
internal layout:

- PIDS replaces the unused legacy `net_prio` cgroup slot.
- DEVICE replaces the unused legacy freezer cgroup slot.
- IPC state uses Android KABI reserve storage.
- bridge-netfilter keeps the stock header view while genksyms calculates CRCs.
- CFS bandwidth preserves scheduler data layouts.
- block throttling places `request_queue::td` in an Android KABI reserve.

These are cgroup/KABI structure slots, not A/B boot slots. Reusing them keeps
the accepted structure sizes but does not make the result ROM-independent.
This release has been adapted and validated only on HyperOS
`OS2.0.211.0.VLFCNXM`; every other ROM requires a fresh KMI, boot and hardware
acceptance cycle.

Direct, non-compatibility cgroup profiles remain only as diagnostic source and
are not inherited by the release profile.

## Build

From the ACK Build `14313284` root:

```bash
git -C common submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_NUMBER=14313284 \
KERNEL_DIR=common \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-ksun-docker" \
DIST_DIR="$PWD/out/diting-ksun-docker/dist" \
build/build.sh -j"$(nproc)"
```

The embedded release must remain:

```text
5.10.236-android12-9-00003-gfb24cf99ad97-ab14313284
```

Before packaging, compare `vmlinux.symvers`, `abi.xml` and `abi_symbollist`
byte-for-byte against the accepted baseline. Repack only from the untouched
stock boot image that matches the installed ROM, then test with
`fastboot boot`.

See [Build and validation](wiki/Build-and-Validation.md) and
[Architecture and KMI](wiki/Architecture-and-KMI.md).
