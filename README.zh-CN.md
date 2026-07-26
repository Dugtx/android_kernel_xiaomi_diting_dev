# Redmi K50 Ultra 内核

简体中文 | [English / 中英主页](README.md)

这是 Redmi K50 Ultra（`diting`，骁龙 8+ Gen 1）的统一公开内核仓库。默认
`main` 分支为 KernelSU-Next + Docker 完整版本；其他长期分支用于复现与协作。

| 分支 | KernelSU-Next | Docker 内核能力 | 用途 |
| --- | --- | --- | --- |
| [`main`](../../tree/main) | 是 | 是 | 推荐完整版本 |
| [`baseline`](../../tree/baseline) | 否 | 否 | 纯净 ACK/GKI 对照基线 |
| [`docker-only`](../../tree/docker-only) | 否 | 是 | 与其他 Root 方案组合的高级用途 |
| [`ksun-only`](../../tree/ksun-only) | 是 | 否 | 只需要内核 Root 的用户 |

项目基于 Google Build `14313284` 对应的 ACK/GKI 5.10，并保持 HyperOS
`OS2.0.211.0.VLFCNXM` 所需的小米厂商模块 ABI。当前只对这一款 ROM 完成适配
和真机验收；未承诺兼容其他 HyperOS 或类原生 ROM。

Docker 相关状态复用的是未启用的 cgroup 槽位和 Android KABI 预留槽位，不是
手机 A/B 启动槽。公开分支不包含 SUSFS 或定位实验代码。

完整的能力、编译、发布、安全与协议说明请阅读项目主页 [README.md](README.md)。
