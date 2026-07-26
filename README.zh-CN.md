# Redmi K50 Ultra 内核——Docker

简体中文 | [English](README.md)

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的 Docker 内核，基于
Google Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。

> **兼容性与实现边界：** 当前只针对 HyperOS
> `OS2.0.211.0.VLFCNXM` 这一款 ROM 完成适配和真机验收，未承诺兼容同设备的
> 其他 HyperOS 版本或类原生 ROM。为保持厂商 ABI，PIDS、DEVICE 等增量状态
> 复用了原内核未启用的 cgroup 槽位和 Android KABI 预留槽位，没有扩大对应冻结
> 结构。这里的“空槽位”是内核结构/KABI 槽位，与手机 A/B 启动槽无关，也不代表
> 内核具备跨 ROM 通用性。

该仓库不包含任何内核 Root 实现，也不包含 KernelSU、SUSFS、Magisk、管理器、
boot 镜像或 Docker 用户态二进制。

## 能力

已验收配置补充了实用容器所需的命名空间、IPC、cgroup、网桥防火墙、NAT、虚拟
网络、CPU 带宽和块 I/O 控制。会改变小米敏感结构布局的功能使用受保护的 KABI
兼容实现。

已验证内核源码提交：

```text
ef369e1cc03c1f2f8030fa7ddd726efb0f59c29f
```

该版本的 `vmlinux.symvers`、`abi.xml` 和 `abi_symbollist` 与纯净设备基线逐字节
一致，并通过临时 `fastboot boot`；Android 完成启动、SELinux Enforcing，厂商
模块、Wi-Fi、相机和音频正常。

## 编译

将仓库检出为匹配 ACK Build `14313284` 工作区中的 `common`：

```bash
HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64.docker-network \
OUT_DIR="$PWD/out/diting-docker" \
DIST_DIR="$PWD/out/diting-docker/dist" \
build/build.sh -j"$(nproc)"
```

不要覆盖 `BUILD_NUMBER`，源码已经保留厂商兼容的内核 release。打包前请阅读
[Docker 配置说明](DOCKER_BASIC.zh-CN.md)。

## Boot 修补边界

只修改 ramdisk 的正常修补不会移除 Docker 能力，前提是编译出的 kernel `Image`
保持不变。如果修补器或刷写模板用原厂或其他内核替换 kernel payload，这些能力
就会丢失。持久刷写前必须比较解包后的 kernel payload，并先执行
`fastboot boot` 临时测试。

## 协议与署名

内核源码和项目修改使用 GPL-2.0-only 及兼容的文件级 SPDX 条款。详情见
[COPYING](COPYING)、[第三方来源](THIRD_PARTY.md)和
[原始 ACK 指南](README.upstream.md)。

维护者：Dugtx。上游贡献者保留其对应代码的作者身份。
