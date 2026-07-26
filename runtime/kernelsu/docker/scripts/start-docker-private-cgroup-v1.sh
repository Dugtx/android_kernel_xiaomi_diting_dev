#!/system/bin/sh

set -eu

DOCKER_ROOT="${DOCKER_ROOT:-/data/local/docker}"
RUNTIME="${DOCKER_RUNTIME:-$DOCKER_ROOT/docker-runtime.sh}"
RUN="$DOCKER_ROOT/run"
BB="${DOCKER_BUSYBOX:-}"

die() {
    echo "[docker-cgroup-v1] ERROR: $*" >&2
    exit 1
}

find_busybox() {
    if [ -n "$BB" ] && [ -x "$BB" ]; then
        return 0
    fi
    for candidate in \
        /data/adb/ksu/bin/busybox \
        /data/adb/magisk/busybox
    do
        if [ -x "$candidate" ]; then
            BB="$candidate"
            return 0
        fi
    done
    candidate="$(command -v busybox 2>/dev/null || true)"
    [ -n "$candidate" ] && [ -x "$candidate" ] && {
        BB="$candidate"
        return 0
    }
    return 1
}

mount_private_view() {
    mkdir -p "$RUN"

    "$BB" mount --make-rprivate / || die "could not privatize mount propagation"

    "$BB" mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup || \
        die "could not create private cgroup root"

    for controller in memory cpu cpuset blkio cpuacct devices; do
        mkdir -p "/sys/fs/cgroup/$controller"
    done

    "$BB" mount -o bind /dev/memcg /sys/fs/cgroup/memory
    "$BB" mount -o bind /dev/cpuctl /sys/fs/cgroup/cpu
    "$BB" mount -o bind /dev/cpuset /sys/fs/cgroup/cpuset
    "$BB" mount -o bind /dev/blkio /sys/fs/cgroup/blkio
    "$BB" mount -t cgroup -o cpuacct none /sys/fs/cgroup/cpuacct

    "$BB" mount -t cgroup -o devices none /sys/fs/cgroup/devices

    echo "private-v1" > "$RUN/cgroup.mode"
}

case "${1:-}" in
    --inside)
        mount_private_view
        DOCKER_CGROUP_MODE=private-v1 \
            DOCKER_NETWORK_MODE="${DOCKER_NETWORK_MODE:-isolated}" \
            "$RUNTIME" start
        ;;
    "")
        [ "$(id -u)" = "0" ] || die "must run as root"
        find_busybox || die "KernelSU or Magisk BusyBox is unavailable"
        [ -x "$RUNTIME" ] || die "Docker runtime is unavailable"
        "$RUNTIME" stop
        DOCKER_BUSYBOX="$BB" exec unshare -m "$0" --inside
        ;;
    *)
        die "usage: $0"
        ;;
esac
