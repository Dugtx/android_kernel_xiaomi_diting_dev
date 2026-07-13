# Docker Basic kernel profile

Author: Dugtx

This profile extends the pinned Android 12 5.10 GKI configuration without
editing Google's `gki_defconfig`. It represents the reproducible replacement
for the earlier ad-hoc Docker Round 2 build.

## Scope

The first round contains only the low-risk options already proven to compile
in the previous Docker Basic output:

- file-handle syscalls used by container runtimes
- devtmpfs support
- tmpfs ACL and extended attributes
- packet, Unix socket, and netlink diagnostics

Namespace and KABI-sensitive options such as `PID_NS`, `SYSVIPC`,
`POSIX_MQUEUE`, and `USER_NS` are intentionally deferred to isolated rounds.

The PID and device cgroup controllers are also separated into dedicated
profiles because the earlier combined candidate did not complete a temporary
boot:

- `build.config.gki.aarch64.docker-cgroup-pids`
- `build.config.gki.aarch64.docker-cgroup-pids-compat`
- `build.config.gki.aarch64.docker-cgroup-device`

Only one experimental controller is added per profile, so a failed boot can be
attributed to a single configuration change.

The direct PIDS profile is retained as a diagnostic reproducer. It passes the
GKI KMI checks, but it increases `CGROUP_SUBSYS_COUNT` from 7 to 8 and grows
the internal `struct css_set` by 24 bytes. The Redmi K50 Ultra returns to its
persistent slot during temporary boot, which is consistent with an out-of-tree
Xiaomi module using the stock cgroup layout without that layout being covered
by the exported KMI symbol CRCs.

The `docker-cgroup-pids-compat` profile instead disables the unused legacy
`net_prio` controller and enables PIDS in its final subsystem slot. This keeps
`CGROUP_SUBSYS_COUNT` and `struct css_set` at their stock sizes. A guarded
genksyms compatibility view retains the stock net_prio enum only while module
symbol CRCs are generated. The override is applied at the Kconfig preprocessor
boundary so all exported cgroup and network types see the stock configuration;
the compiled kernel still contains PIDS instead.
The resulting `vmlinux.symvers` must be byte-identical to the stock ACK build,
and the profile must still pass temporary boot and runtime controller tests
before it is considered safe.

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
