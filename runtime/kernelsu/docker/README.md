# Docker Runtime KernelSU module

[中文](#中文) | [English](#english)

## 中文

这是 Redmi K50 Ultra（`diting`）Docker 内核配套的自包含用户态模块。发布 ZIP
包含固定版本的 Docker Engine、Buildx、Compose、启动脚本与 KernelSU WebUI；普通用户
不需要先通过 ADB 部署二进制。

默认配置偏向日常使用：cgroup v2、隔离网络、8 GiB ext4 数据镜像。WebUI 可以切换
到私有 cgroup v1、启用 Docker bridge、控制开机自启，以及创建或扩容数据镜像。

重要边界：

- 仅支持本仓库说明的 `diting` HyperOS 版本与配套 Docker 内核。
- cgroup v2 是推荐日用模式；private-v1 是在独立挂载命名空间内提供的兼容模式。
- `isolated` 不修改 Android 路由，联网容器可使用 `--network host`。
- `bridge` 会安装可逆的 Android 策略路由；Wi-Fi/移动数据切换后应重启 Docker。
- 镜像只允许扩容，不提供高风险的在线缩容。
- 卸载模块会停止服务，但不会删除 `/data/unencrypted/docker` 中的数据。

安装后，在 KernelSU 管理器打开模块 WebUI，或在 root shell 中使用：

```sh
docker info
docker compose version
diting-docker status
diting-docker doctor
```

## English

This is the self-contained userspace companion for the Redmi K50 Ultra
(`diting`) Docker kernel. Release ZIPs contain pinned Docker Engine, Buildx,
Compose, runtime scripts, and a KernelSU WebUI, so users do not need an ADB
deployment step.

The daily-use default is cgroup v2, isolated networking, and an 8 GiB ext4
data image. The WebUI can switch to a private cgroup v1 view, enable Docker
bridge networking, control automatic startup, and create or grow the image.

Compatibility is intentionally narrow: use the documented `diting` HyperOS
build and matching Docker kernel. Image shrinking is not supported. Uninstalling
the module stops the daemon but preserves `/data/unencrypted/docker`.

## Source and package boundary

Large third-party binaries are not stored in Git. `versions.env` pins every
download and SHA-256 value. `scripts/package-docker-module.sh` applies the
documented equal-length Android path substitutions, assembles the module, and
writes a complete artifact manifest. See `THIRD_PARTY_NOTICES.md`.
