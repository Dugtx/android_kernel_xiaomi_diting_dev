# Redmi K50 Ultra 内核——KernelSU-Next

简体中文 | [English](README.md)

这是面向 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的 KernelSU-Next 内核，
基于 Google Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。

> **兼容性说明：** KernelSU-Next 的功能机制不依赖某一款 ROM；该 KSUN-only
> 变体也不包含 Docker 分支的 cgroup/KABI 空槽位兼容层。但本仓库发布的内核
> `Image` 固定于 Build `14313284` 的 5.10 KMI、内核 release 和小米 vendor
> 模块接口，目前只在 HyperOS `OS2.0.211.0.VLFCNXM` 完成真机验收。复用相同
> vendor/boot ABI 的其他 ROM 可能可用，但未经验证，不能标记为通用刷机包。

该版本只包含 KernelSU-Next，明确不包含 SUSFS、Docker 配置、管理器 APK、boot
镜像或小米闭源文件。

## 固定源码

```text
内核源码：03226eb9315f560d85869d1954de98d8682af2cf
KernelSU-Next：3b18216f71df189ab3d1b1ce0bdb21be1268e771（v3.3.0）
```

KernelSU-Next 通过官方仓库的 Git 子模块固定。内核已通过严格 ACK KMI 检查，
ABI/KMI 输出与纯净设备基线逐字节一致，并通过临时 `fastboot boot`；Android
完成启动、SELinux Enforcing、KernelSU Root 上下文及小米厂商模块正常。

## 编译

```bash
git submodule update --init --recursive

HERMETIC_TOOLCHAIN=0 \
BUILD_CONFIG=common/build.config.gki.aarch64 \
OUT_DIR="$PWD/out/diting-ksun" \
DIST_DIR="$PWD/out/diting-ksun/dist" \
build/build.sh -j"$(nproc)"
```

使用匹配的 ACK Build `14313284` 工作区和 Clang `r416183b`。内核 release 必须
与目标 ROM 保持兼容。

## 安全

只能使用未经修改的原厂 `boot.img` 重打包，持久刷写前先执行 `fastboot boot`，
保留经过校验的原厂镜像用于恢复，并且不要在启动组件被修改时重新锁定
Bootloader。

KernelSU 管理器属于独立用户态组件，本仓库不分发管理器。

## 协议与署名

内核源码及 KernelSU-Next 内核组件使用 GPL-2.0-only。详情见
[COPYING](COPYING)、[第三方来源](THIRD_PARTY.md)、子模块中的 `kernel/LICENSE`
和[原始 ACK 指南](README.upstream.md)。

维护者：Dugtx。上游贡献者保留其对应代码的作者身份。
