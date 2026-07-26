#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

required=(
    module.prop runtime.conf.example customize.sh service.sh action.sh
    uninstall.sh scripts/control.sh scripts/docker-runtime.sh
    scripts/start-docker-private-cgroup-v1.sh system/bin/docker
    system/bin/diting-docker webroot/index.html webroot/style.css webroot/app.js
    THIRD_PARTY_NOTICES.md versions.env
)

for file in "${required[@]}"; do
    [ -s "$MODULE_DIR/$file" ] || {
        echo "missing module source file: $file" >&2
        exit 1
    }
done

for script in "$MODULE_DIR/customize.sh" "$MODULE_DIR/service.sh" \
    "$MODULE_DIR/action.sh" "$MODULE_DIR/uninstall.sh" \
    "$MODULE_DIR/scripts"/*.sh "$MODULE_DIR/system/bin"/*
do
    sh -n "$script"
done

grep -qx 'id=dugtx-docker-dev' "$MODULE_DIR/module.prop"
grep -q 'DOCKER_TARBALL_SHA256=' "$MODULE_DIR/versions.env"
grep -q 'Shell expressions are never evaluated' "$MODULE_DIR/runtime.conf.example"

if grep -En '(^|[;&|[:space:]])(eval|source|\.)[[:space:]]' \
    "$MODULE_DIR/scripts/control.sh" "$MODULE_DIR/service.sh"; then
    echo "configuration path must not evaluate shell input" >&2
    exit 1
fi

echo "Docker module source validation passed."
