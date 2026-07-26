# Security and publication / 安全与发布

## Source boundaries / 源码边界

Published branches contain only reviewable source and documentation. Generated
boot images, APKs, ROM archives, device dumps, logs, credentials and local
absolute paths must remain outside Git.

Before a release:

```bash
git status --short
git ls-files | grep -E '\\.(img|apk|ko|zip|tgz|tar|zst|jsonl)$' && exit 1 || true
git grep -nE '/home/|token|password|private[_ -]?key' -- . ':!README.upstream.md'
git fsck --full --no-reflogs
```

Review the complete reachable history, not only the current file tree.

## Third-party review / 第三方审查

- pin submodules to an exact reviewed commit;
- use the official upstream URL;
- do not execute remote installation scripts during a release build;
- inspect build hooks, generated files and network access;
- record license and provenance in `THIRD_PARTY.md`.

## Licensing / 协议

Kernel derivatives remain subject to GPL-2.0. Additional restrictions such as
“noncommercial use only” must not be added to the kernel's GPL-covered source.
Repository visibility and controlled distribution are operational controls;
they do not change the obligations attached to a distributed GPL derivative.

## Public branch model / 公开分支模型

The repository intentionally publishes four long-lived branches:

| Branch | Public capability set |
| --- | --- |
| `main` | KernelSU-Next + Docker |
| `baseline` | clean ACK/GKI baseline |
| `docker-only` | Docker kernel capabilities only |
| `ksun-only` | KernelSU-Next only |

These branches are release products, not an unrestricted development dump.
Push reviewed topic branches explicitly and open a pull request against the
appropriate base. Do not use `git push --all` or an unqualified
`git push --tags` from a development clone.

本仓库公开四个长期产品分支，不代表可以上传整个本地开发命名空间。开发分支和
tag 都应按名称明确推送，并选择正确的 PR 目标分支。

## Release publication / 发布流程

Create a release tag only when all of the following identify the same source:

- branch and source commit;
- build configuration and toolchain;
- ABI/KMI comparison;
- kernel Image digest;
- package digest and variant name;
- supported ROM and device boundary;
- installation and recovery status.

One project version uses one Release page with clearly named variant packages.
Any untested installer or recovery path must be stated as a Pre-release risk,
not hidden behind a successful kernel build.
