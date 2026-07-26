## 改动说明 / Summary

说明问题、解决方式以及目标分支。

Describe the problem, the proposed change, and the intended target branch.

## 兼容性范围 / Compatibility scope

- 目标分支 / Target branch:
- 目标 ROM / Target ROM: `OS2.0.211.0.VLFCNXM`
- 构建配置 / `BUILD_CONFIG`:
- 工具链 / Toolchain: Clang/LLD `r416183b`

## KMI 与构建检查 / KMI and build checks

- [ ] 每个新提交都包含有效的 `Signed-off-by` / Every new commit has a valid DCO sign-off
- [ ] 使用全新输出目录完成构建 / Built from a clean output directory
- [ ] `vmlinux.symvers` 与 baseline 一致，或已解释差异 / Compared with baseline
- [ ] `abi.xml` 与 baseline 一致，或已解释差异 / Compared with baseline
- [ ] `abi_symbollist` 与 baseline 一致，或已解释差异 / Compared with baseline
- [ ] 未关闭 KMI trimming 或严格 symbol-list 检查 / Strict KMI checks remain enabled
- [ ] 已检查新增配置、依赖和敏感结构布局 / Config dependencies and frozen layouts checked

## 设备测试 / Device testing

- [ ] 尚未进行设备测试 / Not device-tested
- [ ] 已通过 `fastboot boot` 临时测试 / Temporarily tested with `fastboot boot`
- [ ] 已验证日常硬件与厂商模块 / Daily hardware and vendor modules checked

填写测试方式、恢复路径和已知限制。不要上传设备日志中的账号、序列号、定位、
凭据或其他隐私数据。

Describe the test method, recovery path, and known limits. Remove accounts,
serial numbers, location data, credentials, and other private information from
all attached logs.
