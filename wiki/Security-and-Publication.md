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

## Branch publication / 分支发布

Push only the reviewed refs:

```text
baseline/ack-14313284
release/ksun-only
release/ksun-docker
main
```

Do not use `git push --all` or `git push --tags` from a development clone.
Create release tags explicitly after the matching source, ABI report and device
test report have been accepted.
