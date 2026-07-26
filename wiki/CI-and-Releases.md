# CI and release workflows / CI 与发布工作流

The repository uses small automatic checks for every contribution and keeps
the expensive kernel build explicit. A green workflow proves only the checks
listed here; it does not replace on-device boot, hardware, and recovery tests.

本仓库对每次贡献运行轻量自动检查，将耗时较长的内核编译设为显式触发。工作流
通过只代表本文列出的检查通过，不能替代真机开机、硬件功能和恢复测试。

## Policy and source checks / 策略与源码检查

`.github/workflows/policy.yml` runs on pull requests and pushes to the four
long-lived branches. It checks:

- a DCO `Signed-off-by` trailer on every non-merge commit;
- whitespace with `git diff --check`.

The DCO check is implemented in this repository. No third-party DCO action is
granted repository permissions.

## Docker userspace module / Docker 用户态模块

The Docker KernelSU module is maintained and packaged in
[docker-runtime-ksu-modle](https://github.com/Dugtx/docker-runtime-ksu-modle).
Keeping runtime source and release automation there allows this repository's CI
to stay focused on kernel builds and KMI evidence.

Docker KernelSU 模块已迁移至独立项目维护和打包。本仓库只负责内核能力、KMI 证据
与 AnyKernel3 产物，避免两份模块源码长期分叉。

## Reproducible kernel build / 可复现内核编译

`.github/workflows/kernel-build.yml` is a manual workflow with four choices:
`main`, `docker-only`, `ksun-only`, and `baseline`. It reconstructs the exact
ACK Build `14313284` workspace from `ci/manifest-14313284.xml`, including
Clang `r416183b`; it does not follow a moving Android branch.

For every non-baseline variant, the workflow also builds `baseline` in the
same job and requires byte-identical:

- `vmlinux.symvers`;
- `abi.xml`;
- `abi_symbollist`.

It then checks the fixed kernel release string and variant-specific Kconfig
boundaries before uploading the Image and KMI evidence. This is intentionally
manual because a target plus baseline build is storage- and CPU-intensive.

The hosted runner provisions swap and limits Make to two jobs because the
ThinLTO link can exceed the runner's physical memory. This resource guard does
not change the kernel source, configuration, or KMI checks.

随后，工作流会检查固定的内核版本字符串与各变体的 Kconfig 边界，再上传 Image
及 KMI 证据。目标变体与 baseline 的双重编译会消耗较多存储与 CPU，因此该工作流
默认手动触发。公共 runner 会预先配置 swap，并将 Make 并发限制为 2，以避免
ThinLTO 链接超过物理内存；该资源保护不修改内核源码、配置或 KMI 门禁。

Kernel/AnyKernel releases remain separate from the userspace module and require
the device acceptance evidence described in
[Building and KMI checks](Build-and-Validation.md) and
[Flashing and recovery](Flashing-and-Recovery.md).

## Trust boundary / 信任边界

GitHub-hosted CI cannot prove that cellular radio, camera, audio, fingerprint,
thermal behavior, suspend, or Android framework startup work on this phone.
Before marking a kernel release stable, test the exact CI-built Image on the
supported ROM and retain a matching stock `boot.img` recovery path.

GitHub CI 无法证明基带、相机、音频、指纹、温控、待机和 Android Framework 在真机
上正常。稳定发布前必须在支持的 ROM 上测试同一份 CI 产物，并保留匹配的原厂
`boot.img` 恢复路径。
