# Redmi K50 Ultra 内核

[项目主页（中英双语）](README.md#简体中文) | [下载](https://github.com/Dugtx/android_kernel_xiaomi_diting_dev/releases) | [Wiki](wiki/Home.md)

这是 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的设备内核项目，提供四个长期
维护的版本：

| 分支 | 能力 | 用途 |
| --- | --- | --- |
| `main` | KernelSU-Next + Docker | 推荐完整版本 |
| `ksun-only` | KernelSU-Next | 只需要内核 Root |
| `docker-only` | Docker 内核能力 | 配合独立 Root 方案 |
| `baseline` | 纯净 ACK/GKI 基线 | 开发、比较和故障排查 |

当前只支持 HyperOS `OS2.0.211.0.VLFCNXM`。Docker 使用的“空槽位”是内核
cgroup/KABI 结构槽位，不是手机 A/B 启动槽，也不表示兼容其他 ROM。

安装包使用 AnyKernel3，只替换活动 boot 槽中的内核 `Image` 并保留 ramdisk。
安装前必须备份匹配 ROM 的原厂 `boot.img`，保持 Bootloader 解锁并准备 Fastboot
恢复路径。

完整的选包、安装、Docker 用户态、源码编译、KMI 约束和贡献说明请阅读
[README.md](README.md#简体中文)。
