# KernelSU and Docker / KernelSU 与 Docker

## KernelSU-Next

`release/ksun-only`, `release/ksun-docker` and `main` pin
KernelSU-Next `v3.3.0` as a Git submodule. The manager application is not
embedded in the boot ramdisk or distributed in this repository.

The source is built in GKI mode. Root authorization remains a userspace policy
decision made by the matching KernelSU manager; compiling the kernel does not
authorize every application automatically.

## Docker kernel profile

The final profile is:

```text
build.config.gki.aarch64.docker-network
```

It inherits the tested fragments in this order:

1. diagnostics, file handles, devtmpfs and tmpfs metadata
2. KABI-compatible PIDS and DEVICE cgroups
3. PID namespace
4. bridge netfilter and `addrtype`
5. SYSVIPC, POSIX message queues and IPC namespace
6. user namespace
7. CFS bandwidth control
8. block-I/O throttling
9. IPv6 NAT, MACVLAN and VXLAN

Docker userspace, storage images, daemon configuration and Android policy
routing scripts are intentionally separate from the kernel repository.

## Android networking note / Android 网络说明

Docker bridge traffic may need Android policy-routing rules for the active
uplink. A working kernel does not make a static WLAN rule universally correct:
mobile data, Wi-Fi, VPN and tethering use different tables. Runtime scripts
should discover the current uplink, install only owned rules and restore the
previous state on stop.

## Limits / 边界

The public profile does not claim:

- hardware-accelerated CUDA/OpenCL container workloads
- KVM acceleration
- IPVS/Swarm routing mesh
- CRIU checkpoint/restore
- development-machine NFS/SMB or broad USB-peripheral support

These features are outside the published branch scope rather than silently
enabled or experimentally patched.
