#!/system/bin/sh

set -u

MODDIR="${DOCKER_MODULE_DIR:-${0%/*}/..}"
STATE="${DOCKER_STATE:-/data/unencrypted/docker}"
CONFIG="$STATE/runtime.conf"
ROOT="${DOCKER_ROOT:-/data/local/docker}"
RUNTIME="$MODDIR/scripts/docker-runtime.sh"
PRIVATE_V1="$MODDIR/scripts/start-docker-private-cgroup-v1.sh"
LOG="$ROOT/logs/dockerd.log"

AUTO_START=1
CGROUP_MODE=v2
NETWORK_MODE=isolated
DOCKER_IMAGE_SIZE=8G
DNS1=223.5.5.5
DNS2=1.1.1.1

die() {
    echo "[diting-docker] ERROR: $*" >&2
    exit 1
}

valid_image_size() {
    case "$1" in
        [1-9]*G) ;;
        *) return 1 ;;
    esac
    image_size_gib="${1%G}"
    case "$image_size_gib" in *[!0-9]*|"") return 1 ;; esac
    [ "$image_size_gib" -ge 2 ] && [ "$image_size_gib" -le 512 ]
}

valid_ipv4() {
    old_ifs="$IFS"
    IFS=.
    set -- $1
    IFS="$old_ifs"
    [ "$#" -eq 4 ] || return 1
    for octet in "$@"; do
        case "$octet" in *[!0-9]*|"") return 1 ;; esac
        [ "$octet" -ge 0 ] && [ "$octet" -le 255 ] || return 1
    done
}

assign_value() {
    key="$1"
    value="$2"
    case "$key" in
        AUTO_START)
            case "$value" in 0|1) AUTO_START="$value" ;; *) return 1 ;; esac
            ;;
        CGROUP_MODE)
            case "$value" in v2|private-v1) CGROUP_MODE="$value" ;; *) return 1 ;; esac
            ;;
        NETWORK_MODE)
            case "$value" in isolated|bridge) NETWORK_MODE="$value" ;; *) return 1 ;; esac
            ;;
        DOCKER_IMAGE_SIZE)
            valid_image_size "$value" || return 1
            DOCKER_IMAGE_SIZE="$value"
            ;;
        DNS1)
            valid_ipv4 "$value" || return 1
            DNS1="$value"
            ;;
        DNS2)
            valid_ipv4 "$value" || return 1
            DNS2="$value"
            ;;
        *) return 1 ;;
    esac
}

load_config() {
    [ -r "$CONFIG" ] || return 0
    line_number=0
    while IFS= read -r line || [ -n "$line" ]; do
        line_number=$((line_number + 1))
        line="${line%$(printf '\r')}"
        case "$line" in ""|\#*) continue ;; esac
        case "$line" in *=*) ;; *) die "invalid config line $line_number" ;; esac
        key="${line%%=*}"
        value="${line#*=}"
        assign_value "$key" "$value" || \
            die "invalid $key value on config line $line_number"
    done < "$CONFIG"
}

save_config() {
    mkdir -p "$STATE"
    tmp="$CONFIG.tmp.$$"
    {
        echo "# Managed by the Docker Runtime module. Values are not evaluated as shell."
        echo "AUTO_START=$AUTO_START"
        echo "CGROUP_MODE=$CGROUP_MODE"
        echo "NETWORK_MODE=$NETWORK_MODE"
        echo "DOCKER_IMAGE_SIZE=$DOCKER_IMAGE_SIZE"
        echo "DNS1=$DNS1"
        echo "DNS2=$DNS2"
    } > "$tmp" || die "could not write $tmp"
    chmod 0644 "$tmp"
    mv -f "$tmp" "$CONFIG" || die "could not replace $CONFIG"
}

runtime() {
    DOCKER_ROOT="$ROOT" \
    DOCKER_STATE="$STATE" \
    DOCKER_BIN="$MODDIR/bin" \
    DOCKER_CONFIG="$STATE/config" \
    DOCKER_CLI_PLUGIN_EXTRA_DIRS="$MODDIR/cli-plugins" \
    DOCKER_IMAGE_SIZE="$DOCKER_IMAGE_SIZE" \
    DOCKER_NETWORK_MODE="$NETWORK_MODE" \
    DOCKER_CGROUP_MODE="$CGROUP_MODE" \
    DOCKER_DNS1="$DNS1" \
    DOCKER_DNS2="$DNS2" \
        "$RUNTIME" "$@"
}

start_runtime() {
    case "$CGROUP_MODE" in
        v2) runtime start ;;
        private-v1)
            DOCKER_ROOT="$ROOT" \
            DOCKER_RUNTIME="$RUNTIME" \
            DOCKER_BIN="$MODDIR/bin" \
            DOCKER_CONFIG="$STATE/config" \
            DOCKER_CLI_PLUGIN_EXTRA_DIRS="$MODDIR/cli-plugins" \
            DOCKER_IMAGE_SIZE="$DOCKER_IMAGE_SIZE" \
            DOCKER_NETWORK_MODE="$NETWORK_MODE" \
            DOCKER_CGROUP_MODE="$CGROUP_MODE" \
            DOCKER_DNS1="$DNS1" \
            DOCKER_DNS2="$DNS2" \
                "$PRIVATE_V1"
            ;;
    esac
}

print_config() {
    echo "AUTO_START=$AUTO_START"
    echo "CGROUP_MODE=$CGROUP_MODE"
    echo "NETWORK_MODE=$NETWORK_MODE"
    echo "DOCKER_IMAGE_SIZE=$DOCKER_IMAGE_SIZE"
    echo "DNS1=$DNS1"
    echo "DNS2=$DNS2"
}

require_root() {
    [ "$(id -u)" = 0 ] || die "root is required"
}

require_root
mkdir -p "$STATE/config" "$ROOT/logs"
load_config

case "${1:-}" in
    start)
        start_runtime
        ;;
    stop)
        runtime stop
        ;;
    unmount)
        runtime unmount
        ;;
    restart|apply)
        runtime stop
        start_runtime
        ;;
    status)
        print_config
        runtime status
        ;;
    config)
        print_config
        ;;
    get)
        case "${2:-}" in
            AUTO_START) echo "$AUTO_START" ;;
            CGROUP_MODE) echo "$CGROUP_MODE" ;;
            NETWORK_MODE) echo "$NETWORK_MODE" ;;
            DOCKER_IMAGE_SIZE) echo "$DOCKER_IMAGE_SIZE" ;;
            DNS1) echo "$DNS1" ;;
            DNS2) echo "$DNS2" ;;
            *) die "unknown configuration key: ${2:-}" ;;
        esac
        ;;
    set)
        [ "$#" -eq 3 ] || die "usage: $0 set KEY VALUE"
        assign_value "$2" "$3" || die "invalid $2 value: $3"
        save_config
        print_config
        ;;
    resize)
        [ "$#" -eq 2 ] || die "usage: $0 resize SIZE"
        valid_image_size "$2" || die "size must be an integer from 2G through 512G"
        restart_after=0
        if [ -r "$ROOT/run/dockerd.pid" ]; then
            daemon_pid="$(cat "$ROOT/run/dockerd.pid" 2>/dev/null || true)"
            [ -n "$daemon_pid" ] && kill -0 "$daemon_pid" 2>/dev/null && restart_after=1
        fi
        runtime stop
        runtime resize "$2"
        DOCKER_IMAGE_SIZE="$2"
        save_config
        [ "$restart_after" = 0 ] || start_runtime
        ;;
    logs)
        lines="${2:-120}"
        case "$lines" in *[!0-9]*|"") die "log line count must be numeric" ;; esac
        tail -n "$lines" "$LOG" 2>/dev/null || echo "No dockerd log is available."
        ;;
    doctor)
        missing=0
        for tool in chcon e2fsck ip iptables losetup mkfs.ext4 mount \
            resize2fs stat truncate unshare
        do
            if command -v "$tool" >/dev/null 2>&1; then
                echo "tool:$tool=present"
            else
                echo "MISSING tool:$tool"
                missing=1
            fi
        done
        for option in BLK_DEV_LOOP EXT4_FS OVERLAY_FS SECCOMP SECCOMP_FILTER \
            NET_NS PID_NS IPC_NS USER_NS SYSVIPC POSIX_MQUEUE CGROUP_PIDS \
            CGROUP_DEVICE VETH BRIDGE BRIDGE_NETFILTER NETFILTER_XT_MATCH_ADDRTYPE
        do
            if zcat /proc/config.gz 2>/dev/null | grep -q "^CONFIG_$option=y$"; then
                echo "CONFIG_$option=y"
            else
                echo "MISSING CONFIG_$option=y"
                missing=1
            fi
        done
        exit "$missing"
        ;;
    *)
        echo "Usage: $0 {start|stop|unmount|restart|apply|status|config|get KEY|set KEY VALUE|resize SIZE|logs [LINES]|doctor}"
        exit 2
        ;;
esac
