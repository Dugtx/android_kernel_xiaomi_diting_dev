# KernelSU and Docker / KernelSU 与 Docker

## KernelSU-Next

This repository's `main` pins KernelSU-Next `v3.3.0` as a Git submodule. The manager application is not
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

## Accepted device regression / 已通过的真机回归

The `main` release candidate was temporarily booted on HyperOS
`OS2.0.211.0.VLFCNXM` and tested with Docker Engine 28.5.2:

| Area | Result |
| --- | --- |
| default cgroup v2 core | 11 PASS / 0 FAIL |
| bridge networking, DNS and HTTP | 7 PASS / 0 FAIL |
| host networking, DNS and HTTP | 6 PASS / 0 FAIL |
| private cgroup v1 resource controls | 9 PASS / 1 SKIP / 0 FAIL |
| Buildx and Compose | 5 PASS / 0 FAIL |
| IPv6 NAT, macvlan and VXLAN | 8 PASS / 0 FAIL |
| kernel runtime gates | 29 PASS / 1 WARN / 0 FAIL |

The resource-control SKIP is limited to Moby not recognizing the kernel's
BFQ-specific weight interface. Memory, swap, CPU shares, CFS quota, devices,
and a 1 MiB/s block read throttle were enforced. The runtime warning records
that F2FS is unsuitable as an OverlayFS upper on this ROM; a dedicated ext4
data image was used successfully.

Android has no global `/etc/resolv.conf`. The accepted userspace runtime adds
one only inside the dockerd mount namespace and leaves Android's global mount
tree unchanged. Both bridge and host containers passed DNS and HTTP tests.
Registry availability remains an external-network property: during the final
test Docker Hub resolved to an address whose TCP/443 connection also timed out
from the Android host, while local image import and all local build tests
passed.

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
