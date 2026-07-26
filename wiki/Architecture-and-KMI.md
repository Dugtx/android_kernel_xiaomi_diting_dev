# Architecture and KMI / 架构与 KMI

## Boot architecture / 启动架构

The target uses a GKI-style Android boot image:

- the generic arm64 kernel is stored in `boot`
- device ramdisks and hardware policy remain Xiaomi-controlled
- hardware drivers are largely out-of-tree modules under vendor partitions
- A/B slots and AVB protect the boot chain

This means a kernel can compile successfully and still fail during Android
startup if a Xiaomi module cannot resolve a symbol or expects a frozen internal
layout.

## Compatibility rule / 兼容原则

The accepted ACK build is the compatibility baseline. Every branch must retain:

1. the exact `UTS_RELEASE` and module `vermagic`;
2. the exported KMI symbol names;
3. symbol CRCs used by Xiaomi modules;
4. internal layouts known to be consumed by those modules.

The project does not solve compatibility by turning off
`TRIM_NONLISTED_KMI` or strict symbol-list checks. Instead, small guarded KABI
adapters preserve the stock genksyms view and reuse Android KABI reserve fields
where a runtime structure needs additional state.

## Current compatibility adapters / 当前兼容层

- PIDS cgroup replaces an unused legacy slot without growing `css_set`
- DEVICE cgroup replaces the unused legacy freezer slot while cgroup-v2 freeze
  remains available
- IPC namespace state uses reserved Android KABI space
- bridge-netfilter headers retain the stock genksyms view
- CFS bandwidth state preserves scheduler layouts and symbol CRCs
- block throttling uses an Android KABI reserve in `request_queue`

“空槽位 / spare slot”在本文中只表示上述未启用的 cgroup 槽位或 Android KABI
reserve 字段，与设备的 A/B boot slot 无关。它维持当前参考 ROM 的结构尺寸，
但不能证明其他 ROM 与相同布局、符号 CRC 或厂商模块兼容。

The adapters are device- and baseline-specific. They should not be copied to a
different kernel release without BTF/layout, symbol CRC and real-device tests.

## QRTR warning / QRTR 警告

Qualcomm QRTR endpoint symbols are required by Xiaomi modules such as
`qrtr-smd.ko`. Modifying exported QRTR functions or their parsed type context
can change genksyms CRCs even when the C signature appears unchanged. A QRTR
module-load failure can break modem services and leave Android at the boot
animation. Keep unrelated experiments outside exported vendor interfaces and
always inspect early module-load errors after a temporary boot.
