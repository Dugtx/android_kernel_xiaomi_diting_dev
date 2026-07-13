# Docker Basic kernel profile

Author: Dugtx

This profile extends the pinned Android 12 5.10 GKI configuration without
editing Google's `gki_defconfig`. It represents the reproducible replacement
for the earlier ad-hoc Docker Round 2 build.

## Scope

The first round contains only the low-risk options already proven to compile
in the previous Docker Basic output:

- PID and device cgroup controllers
- file-handle syscalls used by container runtimes
- devtmpfs support
- tmpfs ACL and extended attributes
- packet, Unix socket, and netlink diagnostics

Namespace and KABI-sensitive options such as `PID_NS`, `SYSVIPC`,
`POSIX_MQUEUE`, and `USER_NS` are intentionally deferred to isolated rounds.

## Build

From the ACK build root:

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-basic \
OUT_DIR=/home/dugtx/project_important/Kernel_Build/out/docker-basic \
DIST_DIR=/home/dugtx/project_important/Kernel_Build/out/docker-basic/dist \
build/build.sh
```

Do not set `BUILD_NUMBER`: this source revision already carries the matching
Android build suffix. The kernel release must remain compatible with Xiaomi's
vendor modules.

Boot images must be repacked from the untouched fastboot-ROM `boot.img`, and
each new round must pass temporary `fastboot boot` validation before flashing.
