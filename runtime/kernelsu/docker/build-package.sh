#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$MODULE_DIR/../../.." && pwd)"
# shellcheck source=versions.env
source "$MODULE_DIR/versions.env"
MODULE_VERSION="$(sed -n 's/^version=//p' "$MODULE_DIR/module.prop")"
[ -n "$MODULE_VERSION" ] || {
    echo "ERROR: module version is missing" >&2
    exit 1
}

WORK_DIR="${WORK_DIR:-$REPO_ROOT/out/docker-module}"
OUTPUT="${OUTPUT:-$REPO_ROOT/out/diting-docker-kernelsu-v$MODULE_VERSION.zip}"
RUNTIME_DIR=""
PLUGIN_DIR=""
DOWNLOAD=0

die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: build-package.sh [OPTIONS]

Options:
  --download                 Download every pinned upstream input
  --runtime-dir DIRECTORY    Use an already Android-patched Docker runtime
  --plugin-dir DIRECTORY     Use existing docker-buildx/docker-compose files
  --output FILE              Output module ZIP path

Use either --download, or both --runtime-dir and --plugin-dir.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --download) DOWNLOAD=1; shift ;;
        --runtime-dir) RUNTIME_DIR="$2"; shift 2 ;;
        --plugin-dir) PLUGIN_DIR="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

case "$OUTPUT" in
    /*) ;;
    *) OUTPUT="$PWD/$OUTPUT" ;;
esac
case "$WORK_DIR" in
    ""|/|"$REPO_ROOT") die "unsafe WORK_DIR: $WORK_DIR" ;;
esac

download_file() {
    url="$1"
    destination="$2"
    expected="$3"
    mkdir -p "${destination%/*}"
    if [ ! -s "$destination" ]; then
        curl --fail --location --retry 3 --retry-all-errors \
            --output "$destination" "$url"
    fi
    echo "$expected  $destination" | sha256sum --check -
}

patch_runtime() {
    upstream="$1"
    runtime="$2"
    rm -rf "$runtime"
    cp -a "$upstream" "$runtime"

    patch_pair() {
        old_path="$1"
        new_path="$2"
        expected="$3"
        [ "${#old_path}" -eq "${#new_path}" ] || \
            die "replacement paths must have equal length"
        matches=0
        for file in "$runtime"/*; do
            [ -f "$file" ] || continue
            count="$(LC_ALL=C grep -ao "$old_path" "$file" 2>/dev/null | wc -l || true)"
            if [ "$count" -gt 0 ]; then
                OLD_PATH="$old_path" NEW_PATH="$new_path" perl -0pi -e \
                    's|\Q$ENV{OLD_PATH}\E|$ENV{NEW_PATH}|g' "$file"
                matches=$((matches + count))
            fi
        done
        [ "$matches" -eq "$expected" ] || \
            die "expected $expected matches for $old_path, found $matches"
        ! LC_ALL=C grep -aql "$old_path" "$runtime"/* || \
            die "old path remains after patching: $old_path"
    }

    patch_pair /run/containerd /data/local/ctr 11
    patch_pair /var/run/docker /data/local/dkr 6
    patch_pair /run/docker /data/local 3
}

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/downloads" "$WORK_DIR/stage"

if [ "$DOWNLOAD" = 1 ]; then
    tarball="$WORK_DIR/downloads/docker-$DOCKER_VERSION.tgz"
    download_file \
        "https://download.docker.com/linux/static/stable/aarch64/docker-$DOCKER_VERSION.tgz" \
        "$tarball" "$DOCKER_TARBALL_SHA256"
    mkdir -p "$WORK_DIR/upstream"
    tar -xzf "$tarball" -C "$WORK_DIR/upstream"
    patch_runtime "$WORK_DIR/upstream/docker" "$WORK_DIR/runtime"
    RUNTIME_DIR="$WORK_DIR/runtime"

    mkdir -p "$WORK_DIR/plugins"
    download_file \
        "https://github.com/docker/buildx/releases/download/v$BUILDX_VERSION/buildx-v$BUILDX_VERSION.linux-arm64" \
        "$WORK_DIR/plugins/docker-buildx" "$BUILDX_SHA256"
    download_file \
        "https://github.com/docker/compose/releases/download/v$COMPOSE_VERSION/docker-compose-linux-aarch64" \
        "$WORK_DIR/plugins/docker-compose" "$COMPOSE_SHA256"
    PLUGIN_DIR="$WORK_DIR/plugins"
fi

[ -d "$RUNTIME_DIR" ] || die "use --download or provide --runtime-dir"
[ -d "$PLUGIN_DIR" ] || die "use --download or provide --plugin-dir"

for name in containerd containerd-shim-runc-v2 ctr docker docker-init \
    docker-proxy dockerd runc
do
    [ -x "$RUNTIME_DIR/$name" ] || die "missing runtime executable: $name"
done
for name in docker-buildx docker-compose; do
    [ -x "$PLUGIN_DIR/$name" ] || die "missing CLI plugin: $name"
done

stage="$WORK_DIR/stage"
cp -a "$MODULE_DIR/module.prop" "$MODULE_DIR/runtime.conf.example" \
    "$MODULE_DIR/customize.sh" "$MODULE_DIR/service.sh" \
    "$MODULE_DIR/action.sh" "$MODULE_DIR/uninstall.sh" \
    "$MODULE_DIR/README.md" "$MODULE_DIR/THIRD_PARTY_NOTICES.md" "$stage/"
cp -a "$MODULE_DIR/scripts" "$MODULE_DIR/system" "$MODULE_DIR/webroot" "$stage/"
mkdir -p "$stage/bin" "$stage/cli-plugins" "$stage/LICENSES"
cp -a "$RUNTIME_DIR"/* "$stage/bin/"
cp -a "$PLUGIN_DIR/docker-buildx" "$PLUGIN_DIR/docker-compose" "$stage/cli-plugins/"
cp "$REPO_ROOT/LICENSES/dual/Apache-2.0" "$stage/LICENSES/Apache-2.0.txt"
{
    echo "docker_version=$DOCKER_VERSION"
    echo "docker_tarball_sha256=$DOCKER_TARBALL_SHA256"
    echo "buildx_version=$BUILDX_VERSION"
    echo "buildx_sha256=$BUILDX_SHA256"
    echo "compose_version=$COMPOSE_VERSION"
    echo "compose_sha256=$COMPOSE_SHA256"
    if git -C "$REPO_ROOT" rev-parse HEAD >/dev/null 2>&1; then
        echo "source_revision=$(git -C "$REPO_ROOT" rev-parse HEAD)"
    fi
} > "$stage/UPSTREAM_PROVENANCE.txt"

find "$stage" -type d -exec chmod 0755 {} +
find "$stage" -type f -exec chmod 0644 {} +
chmod 0755 "$stage/customize.sh" "$stage/service.sh" "$stage/action.sh" \
    "$stage/uninstall.sh" "$stage/scripts"/*.sh "$stage/system/bin"/* \
    "$stage/bin"/* "$stage/cli-plugins"/*

for script in "$stage/customize.sh" "$stage/service.sh" "$stage/action.sh" \
    "$stage/uninstall.sh" "$stage/scripts"/*.sh "$stage/system/bin"/*
do
    sh -n "$script"
done

(
    cd "$stage"
    find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

source_epoch="$(git -C "$REPO_ROOT" show -s --format=%ct HEAD 2>/dev/null || echo 0)"
find "$stage" -exec touch -d "@$source_epoch" {} +

output_dir="$(dirname -- "$OUTPUT")"
output_name="$(basename -- "$OUTPUT")"
mkdir -p "$output_dir"
rm -f "$OUTPUT" "$OUTPUT.sha256"
(
    cd "$stage"
    find . -type f -print0 | sort -z | xargs -0 zip -X -9 "$OUTPUT"
)
(cd "$output_dir" && sha256sum "$output_name" > "$output_name.sha256")
unzip -t "$OUTPUT"

echo "Built $OUTPUT"
cat "$OUTPUT.sha256"
