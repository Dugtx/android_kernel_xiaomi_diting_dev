# Redmi K50 Ultra Docker 内核配置

[English](DOCKER_BASIC.md) | 简体中文

作者：Dugtx

该分支在固定的 Android 12 5.10 GKI 基线上加入已经验收的容器能力，最终构建
配置为 `build.config.gki.aarch64.docker-network`。它不包含 KernelSU、SUSFS、
Magisk、Root 管理器或修改后的 Android ramdisk；Root 和用户态 Docker 运行时
属于独立部署层。

## 能力范围

该配置以分阶段、可归因的方式补充：

- 容器运行时需要的文件句柄、devtmpfs、tmpfs ACL 与扩展属性；
- PID、IPC 与用户命名空间；
- PIDS 和 DEVICE cgroup 控制器；
- CFS CPU 带宽控制与块 I/O 限速；
- 网桥 netfilter、连接跟踪、NAT/MASQUERADE 与必要的虚拟网络驱动；
- socket、packet 与 netlink 诊断接口。

涉及小米闭源厂商模块内部布局的配置使用受保护的 KABI 兼容实现。最终
`vmlinux.symvers`、`abi.xml` 与 `abi_symbollist` 必须和纯净 ACK 基线逐字节一致。

## 兼容性与空槽位说明

当前发布版仅为 HyperOS `OS2.0.211.0.VLFCNXM` 适配并完成真机验收，不是面向
其他 HyperOS 或类原生 ROM 的通用 GKI 内核。更换 ROM 后必须重新完成厂商模块
KMI 对比、临时启动和硬件功能验收。

为避免扩大厂商模块可能依赖的冻结结构，PIDS 复用原配置未启用的 legacy
`net_prio` cgroup 槽位，DEVICE 复用未启用的 legacy freezer cgroup 槽位，IPC、
CFS bandwidth 和块 I/O 限速状态则复用 Android KABI reserve 字段。这里所说的
“空槽位”是 cgroup/KABI 内部结构的空闲或预留槽位，不是手机的 A/B 启动槽，
也不会自然带来跨 ROM 兼容能力。

## 已验证环境

目标设备为 Redmi K50 Ultra（`diting`），系统为 HyperOS
`OS2.0.211.0.VLFCNXM`。该分支已通过完整编译、严格 KMI 检查、临时
`fastboot boot`、厂商模块加载、Wi-Fi、相机和音频检查。没有写入持久 boot 槽。

## 编译

在 ACK 构建根目录执行：

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR=/absolute/path/to/out/docker-only \
DIST_DIR=/absolute/path/to/out/docker-only/dist \
build/build.sh
```

不要额外设置 `BUILD_NUMBER`，源码已经保留和小米厂商模块匹配的内核 release。
必须使用原厂线刷包中未被 Magisk 等工具修改的 `boot.img` 作为解包和重打包基线，
并在任何持久刷写前先执行 `fastboot boot` 临时测试。

## 自行修补 boot 的边界

正常的 Magisk 或其他只修改 ramdisk 的 boot 修补不会让 Docker 内核能力失效，
前提是修补后的镜像仍然保留该分支编译出的同一份 `Image`。

如果修补器或刷写模板把 `Image` 换成原厂或其他内核，Docker 能力就会丢失。
修补后应分别解包前后两个 boot 镜像并比较 kernel payload 哈希，同时保持 boot
header、vendor_boot、设备树、厂商模块和内核 release 与目标 ROM 相容。
