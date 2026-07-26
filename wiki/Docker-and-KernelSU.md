# KernelSU and Docker / KernelSU 与 Docker

KernelSU-Next and Docker solve different parts of the system. KernelSU-Next
provides controlled root access. The Docker profile provides kernel features
for containers. Docker Engine, storage, networking policy, and startup remain
userspace responsibilities.

KernelSU-Next 与 Docker 负责不同层次：前者提供可控 Root，后者需要内核容器能力。
Docker Engine、镜像存储、网络策略和开机服务仍属于用户态。

## KernelSU-Next

`main` and `ksun-only` pin KernelSU-Next `v3.3.0` as a Git submodule. The
manager APK is not included in the source repository or AnyKernel3 package.
Root authorization is controlled by the matching manager after Android boots;
the kernel does not authorize every application automatically.

`main` 和 `ksun-only` 通过 Git 子模块固定 KernelSU-Next `v3.3.0`。仓库和刷机包
不内置管理器 APK。Android 启动后仍需由匹配的管理器控制应用授权。

KernelSU packages require a clean stock ramdisk. Their AnyKernel3 installer
aborts when it detects Magisk or another ramdisk modification, preventing an
accidental dual-root setup. `docker-only` has no kernel root and therefore
requires a separate compatible root method to prepare mounts and start
`dockerd`.

## Docker kernel profile / Docker 内核配置

`main` and `docker-only` use:

```text
build.config.gki.aarch64.docker-network
```

The profile adds:

1. file handles, devtmpfs, tmpfs metadata, and diagnostic interfaces;
2. PID, IPC, and user namespaces;
3. SYSVIPC and POSIX message queues;
4. KABI-compatible PIDS and DEVICE cgroups;
5. CFS bandwidth and block-I/O throttling;
6. OverlayFS and container filesystem dependencies;
7. veth, bridge netfilter, conntrack, NAT, and MASQUERADE;
8. IPv6 NAT, macvlan, and VXLAN.

Changes that need additional runtime state use guarded KABI adapters described
in [Architecture and KMI](Architecture-and-KMI.md). The cgroup/KABI spare
slots are not phone A/B boot slots.

## Userspace required / 仍需用户态

Installing a Docker kernel does not install a `docker` command. A usable
environment must separately provide:

- AArch64 Docker client, `dockerd`, containerd, runc, and optional plugins;
- an ext4 data store suitable for OverlayFS;
- daemon state and socket paths writable on Android;
- DNS configuration visible to dockerd without modifying `/system`;
- cgroup and network setup scripts;
- an optional KernelSU startup module.

安装 Docker 内核后不会自动出现 `docker` 命令。还需要单独部署 AArch64 用户态、
ext4 存储、DNS、cgroup、网络脚本和可选的开机模块。

HyperOS data storage is F2FS and is not used directly as the OverlayFS upper
for this runtime design. A dedicated ext4 image avoids changing the Android
filesystem and keeps container data removable. Android also has no global
`/etc/resolv.conf`; a runtime should provide resolver configuration only in
dockerd's private mount namespace rather than making `/system` writable.

## cgroup modes / cgroup 模式

| Mode | Recommended use | Available controls | Android impact |
| --- | --- | --- | --- |
| cgroup v2 | daily development and long-running services | namespaces, PIDS, normal container lifecycle | keeps Android's existing layout |
| private cgroup v1 | workloads needing explicit resource limits | memory, swap, CPU shares/quota, devices, blkio bandwidth | visible only inside Docker's private mount namespace |

Use cgroup v2 by default for daily phone use. Switch to private cgroup v1 only
when a workload needs the additional resource controllers. The private view
must not replace or remount Android's global cgroup hierarchy.

日用默认选择 cgroup v2；只有在容器需要内存、CPU、devices 或 blkio 限制时才使用
private-v1。私有视图不能修改 Android 全局 cgroup 层级。

BFQ exposes a kernel-specific weight interface that Moby does not recognize as
the standard blkio weight file. Bandwidth throttling is available, while BFQ
weight should be treated as unsupported by the current userspace combination.

## Networking / 网络

The safest daily mode disables Docker's bridge and uses `--network host` for
containers that need connectivity. Conventional bridge mode is also supported,
but Android routes Wi-Fi, mobile data, VPN, and tethering through different
policy tables. A userspace runtime must:

1. detect the active uplink table;
2. install only its own `docker0` policy rules;
3. update them when the uplink changes;
4. restore previous rules and sysctls when Docker stops.

Do not hard-code one WLAN table into the kernel. DNS and policy routing are
runtime concerns, not kernel configuration options.

## Scope and limits / 能力边界

The public Docker profile does not provide:

- Docker userspace or a ready-to-run Linux distribution;
- hardware-accelerated CUDA/OpenCL container workloads;
- KVM acceleration (`/dev/kvm` is not exposed by the stock boot chain);
- IPVS/Swarm routing mesh;
- CRIU checkpoint/restore;
- guaranteed compatibility with another ROM.

Version-specific test coverage and known issues belong to each
[GitHub Release](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases),
so this page can remain a stable description of how the feature works.
