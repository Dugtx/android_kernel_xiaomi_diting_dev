# 参与贡献 / Contributing

感谢你改进 Redmi K50 Ultra（`diting`）内核。这个项目与小米闭源 vendor 模块
共同启动，因此“能够编译”不是充分条件；KMI、符号 CRC 和敏感结构布局都是
合并要求。

## 选择目标分支

| 改动范围 | Pull Request 目标分支 |
| --- | --- |
| ACK 基线、通用修复、公共文档 | `baseline`，或由维护者确认后同步到其他分支 |
| Docker、namespace、cgroup、容器网络 | `docker-only` |
| KernelSU-Next 集成 | `ksun-only` |
| 只在 KernelSU-Next 与 Docker 组合中出现的问题 | `main` |

四个长期分支是独立发布产品。不要通过把 `baseline`、`docker-only` 或
`ksun-only` 整体合并进 `main` 来“同步能力”；公共修复应以可审查的提交进行
移植。无法确定目标时，先开 Issue 描述影响范围。

## DCO 签署

所有新提交必须遵守仓库根目录的 [Developer Certificate of Origin 1.1](DCO)，
并包含与提交者身份一致的 `Signed-off-by`。使用 Git 自动生成签署行：

```bash
git commit -s
```

签署表示提交者确认有权按照文件现有的开源许可证提交和分发该贡献。DCO 不转让
版权，也不能替代现有 SPDX、作者和第三方许可证信息。不要为其他贡献者伪造或
代填签署行。

## 开发环境

使用与项目匹配的输入：

- ACK `android12-5.10-2025-05_r6`
- Google Build `14313284`
- Clang/LLD `r416183b` (`12.0.5`)
- 当前分支固定的 `.scmversion`
- KernelSU 分支固定的 Git 子模块提交

完整目录结构和构建命令见
[源码编译与 KMI 检查](wiki/Build-and-Validation.md)。每个分支和提交使用独立
输出目录，不要复用其他变体的 `.config` 或构建产物。

## 必须提供的检查

Pull Request 应说明：

1. 改动解决的问题和适用分支；
2. 使用的 `BUILD_CONFIG`、源码提交和工具链；
3. 构建是否成功；
4. 与 `baseline` 比较 `vmlinux.symvers`、`abi.xml` 和 `abi_symbollist` 的结果；
5. 新增配置及其依赖；
6. 是否涉及导出函数、vendor 模块接口或冻结结构；
7. 如已进行设备测试，使用的 ROM、启动方式和恢复路径。

以下输出出现差异时，不要直接提交设备测试：

```bash
cmp baseline/dist/vmlinux.symvers "$DIST_DIR/vmlinux.symvers"
cmp baseline/dist/abi.xml "$DIST_DIR/abi.xml"
cmp baseline/dist/abi_symbollist "$DIST_DIR/abi_symbollist"
```

不得通过关闭 `TRIM_NONLISTED_KMI`、`KMI_SYMBOL_LIST_STRICT_MODE` 或其他严格
检查规避兼容性问题。

## 提交范围

- 保持提交小而明确，配置、KABI 适配和文档应便于独立审查；
- 不要混入格式化整个内核树、无关调优或未经说明的二进制；
- 不要提交 boot/ROM 镜像、APK、`.ko`、固件、设备转储、日志、凭据或本地路径；
- 第三方代码必须记录上游地址、固定版本、许可证和引入方式；
- 不要移除现有作者、SPDX 标识或上游许可证。

## 设备测试

设备测试只适用于 Redmi K50 Ultra 的 HyperOS
`OS2.0.211.0.VLFCNXM`。首次测试必须使用 `fastboot boot` 和匹配 ROM 的纯净
ramdisk，不应直接持久刷写。SELinux、QRTR、Wi-Fi、相机、音频、电话和厂商模块
加载状态属于基本检查项。具体流程见[安装与恢复](wiki/Flashing-and-Recovery.md)。

---

Thank you for improving the Redmi K50 Ultra (`diting`) kernel. This project
boots together with proprietary Xiaomi vendor modules, so a successful build
is not sufficient for merging. KMI, symbol CRCs, and sensitive structure
layouts are part of the compatibility contract.

## Choose the target branch

| Change scope | Pull request base |
| --- | --- |
| ACK baseline, common fixes, shared documentation | `baseline`, then forward-port with maintainer guidance |
| Docker, namespaces, cgroups, or container networking | `docker-only` |
| KernelSU-Next integration | `ksun-only` |
| A problem unique to the combined KernelSU-Next and Docker product | `main` |

The four long-lived branches are independent release products. Do not merge
an entire variant branch into `main` merely to synchronize features. Forward-
port shared fixes as reviewable commits. Open an Issue first when the correct
base is unclear.

## DCO sign-off

Every new commit must comply with the
[Developer Certificate of Origin 1.1](DCO) and carry a `Signed-off-by` trailer
matching the contributor's identity. Let Git add it with:

```bash
git commit -s
```

The sign-off certifies that the contributor has the right to submit and
redistribute the change under the license indicated in the affected files.
It does not transfer copyright or replace SPDX, authorship, or third-party
license records. Never fabricate another contributor's sign-off.

## Development environment

Use the project inputs together:

- ACK `android12-5.10-2025-05_r6`
- Google Build `14313284`
- Clang/LLD `r416183b` (`12.0.5`)
- the selected branch's pinned `.scmversion`
- the pinned Git submodule revision on KernelSU branches

See [Building and KMI checks](wiki/Build-and-Validation.md) for the workspace
layout and commands. Use a fresh output directory for every branch and commit;
do not reuse another variant's `.config` or build artifacts.

## Required evidence

A pull request should state:

1. the problem being solved and intended branch;
2. source revision, `BUILD_CONFIG`, and toolchain;
3. whether the build completed;
4. the comparison result for `vmlinux.symvers`, `abi.xml`, and
   `abi_symbollist` against `baseline`;
5. added configuration and dependencies;
6. whether exported functions, vendor interfaces, or frozen layouts change;
7. when device-tested, the ROM, boot method, and recovery path.

Do not proceed to device testing when these comparisons differ unexpectedly:

```bash
cmp baseline/dist/vmlinux.symvers "$DIST_DIR/vmlinux.symvers"
cmp baseline/dist/abi.xml "$DIST_DIR/abi.xml"
cmp baseline/dist/abi_symbollist "$DIST_DIR/abi_symbollist"
```

Disabling `TRIM_NONLISTED_KMI`, `KMI_SYMBOL_LIST_STRICT_MODE`, or another
strict check is not an acceptable compatibility fix.

## Change scope

- Keep commits small, explicit, and independently reviewable.
- Do not mix tree-wide formatting, unrelated tuning, or unexplained binaries.
- Do not commit boot/ROM images, APKs, `.ko` files, firmware, device dumps,
  logs, credentials, or local absolute paths.
- Record the source, pinned version, license, and integration method for
  third-party code.
- Preserve existing authorship, SPDX identifiers, and upstream licenses.

## Device testing

Device testing applies only to HyperOS `OS2.0.211.0.VLFCNXM` on Redmi K50
Ultra. First boot the test image with `fastboot boot` and a clean matching
ramdisk; do not persist it immediately. SELinux, QRTR, Wi-Fi, camera, audio,
telephony, and vendor-module loading are baseline checks. See
[Flashing and recovery](wiki/Flashing-and-Recovery.md).
