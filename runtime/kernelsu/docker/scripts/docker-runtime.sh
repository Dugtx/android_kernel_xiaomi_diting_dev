#!/system/bin/sh

set -u

DOCKER_ROOT="${DOCKER_ROOT:-/data/local/docker}"
DOCKER_STATE="${DOCKER_STATE:-/data/unencrypted/docker}"
DOCKER_IMAGE="${DOCKER_IMAGE:-$DOCKER_STATE/data.ext4}"
DOCKER_IMAGE_SIZE="${DOCKER_IMAGE_SIZE:-8G}"
DOCKER_MOUNT="${DOCKER_MOUNT:-$DOCKER_ROOT/store}"
DOCKER_NETWORK_MODE="${DOCKER_NETWORK_MODE:-isolated}"
DOCKER_CGROUP_MODE="${DOCKER_CGROUP_MODE:-v2}"
DOCKER_DNS1="${DOCKER_DNS1:-223.5.5.5}"
DOCKER_DNS2="${DOCKER_DNS2:-1.1.1.1}"

BIN="${DOCKER_BIN:-$DOCKER_ROOT/bin}"
RUN="$DOCKER_ROOT/run"
LOG="$DOCKER_ROOT/logs"
DATA_ROOT="$DOCKER_MOUNT/docker-data"
SOCKET="$RUN/docker.sock"
PIDFILE="$RUN/dockerd.pid"
SHIM_STATE="/data/local/ctr"
DNS_FILE="/data/local/dnsv"
NETWORK_STATE="$RUN/network.state"
NETWORK_MODE_FILE="$RUN/network.mode"

export PATH="$BIN:/system/bin:/system/xbin"
export DOCKER_HOST="unix://$SOCKET"
export DOCKER_CONFIG="${DOCKER_CONFIG:-$DOCKER_STATE/config}"
export DOCKER_CLI_PLUGIN_EXTRA_DIRS="${DOCKER_CLI_PLUGIN_EXTRA_DIRS:-}"
# Android does not ship /etc/resolv.conf. The daemon launcher below supplies it
# in a private mount namespace, so the stock Go resolver and Docker's standard
# container /etc/resolv.conf destination can both remain unmodified.
export GODEBUG="${GODEBUG:-netdns=go}"

log() {
    echo "[docker-runtime] $*"
}

die() {
    echo "[docker-runtime] ERROR: $*" >&2
    exit 1
}

require_root() {
    [ "$(id -u)" = "0" ] || die "must run as root"
}

require_binary() {
    [ -x "$BIN/$1" ] || die "missing executable: $BIN/$1"
}

is_mounted() {
    awk -v target="$DOCKER_MOUNT" '$2 == target { found=1 } END { exit !found }' \
        /proc/mounts
}

image_loop() {
    losetup -j "$DOCKER_IMAGE" 2>/dev/null | sed -n '1s/:.*//p'
}

daemon_running() {
    [ -f "$PIDFILE" ] || return 1
    pid="$(cat "$PIDFILE" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

busybox_path() {
    for candidate in \
        /data/adb/ksu/bin/busybox \
        /data/adb/magisk/busybox \
        "$(command -v busybox 2>/dev/null)"
    do
        [ -n "$candidate" ] && [ -x "$candidate" ] && {
            echo "$candidate"
            return 0
        }
    done
    return 1
}

run_daemon_in_mount_namespace() {
    bb="$(busybox_path)" || die "BusyBox is required for private mount propagation"
    etc_root="$RUN/daemon-etc"
    etc_lower="$etc_root/lower"
    etc_view="$etc_root/view"

    # unshare(1) creates the namespace; making it recursively private ensures
    # the temporary /system/etc view can never propagate back into Android.
    "$bb" mount --make-rprivate / || \
        die "could not make the daemon mount namespace private"
    rm -rf "$etc_root"
    mkdir -p "$etc_lower" "$etc_view"
    "$bb" mount --bind /system/etc "$etc_lower" || \
        die "could not preserve Android /system/etc in the daemon namespace"

    # Overlay-on-overlay is rejected by this vendor kernel. A symlink view
    # retains every original top-level entry and adds only resolv.conf.
    for entry in "$etc_lower"/*; do
        [ -e "$entry" ] || continue
        ln -s "$entry" "$etc_view/${entry##*/}" || \
            die "could not construct the private /system/etc view"
    done
    cp "$DNS_FILE" "$etc_view/resolv.conf" || \
        die "could not stage the private resolver configuration"
    "$bb" mount --bind "$etc_view" /system/etc || \
        die "could not install the private resolver view"
    [ -r /etc/resolv.conf ] || die "private /etc/resolv.conf is unavailable"

    exec dockerd "$@"
}

cleanup_project_netns_mounts() {
    prefix="$RUN/docker/netns"
    attempts=0

    # libnetwork bind-mounts each network namespace below exec-root. If a
    # daemon is killed before it removes those mounts, rm -rf reports EBUSY.
    # Select only this project-owned prefix and peel stacked mounts from the
    # end of /proc/mounts; never inspect or unmount Android's global netns.
    while [ "$attempts" -lt 64 ]; do
        target="$(awk -v prefix="$prefix" '
            $2 == prefix || index($2, prefix "/") == 1 { target=$2 }
            END { print target }
        ' /proc/mounts)"
        [ -n "$target" ] || return 0
        if ! umount "$target" 2>/dev/null; then
            log "could not unmount stale project netns: $target"
            return 1
        fi
        attempts=$((attempts + 1))
    done

    log "project netns cleanup reached its safety limit"
    return 1
}

read_sysctl() {
    cat "/proc/sys/$1" 2>/dev/null
}

write_sysctl() {
    value="$1"
    path="$2"
    [ -e "/proc/sys/$path" ] || return 0
    echo "$value" > "/proc/sys/$path" || \
        die "could not set /proc/sys/$path=$value"
}

save_network_state() {
    [ -e "$NETWORK_STATE" ] && return 0
    {
        echo "ip_forward=$(read_sysctl net/ipv4/ip_forward)"
        echo "bridge_iptables=$(read_sysctl net/bridge/bridge-nf-call-iptables)"
        echo "bridge_ip6tables=$(read_sysctl net/bridge/bridge-nf-call-ip6tables)"
        echo "bridge_arptables=$(read_sysctl net/bridge/bridge-nf-call-arptables)"
        echo "bridge_uplink_table="
        echo "bridge_subnet="
        echo "bridge_iif_added=0"
        echo "bridge_return_added=0"
    } > "$NETWORK_STATE"
}

prepare_bridge_network() {
    save_network_state

    # HyperOS enables br_netfilter globally. On this vendor kernel that path
    # consumes Docker bridge IPv4 frames before the routed FORWARD/NAT hooks.
    # Docker's ordinary routed iptables chains remain active with these off.
    write_sysctl 0 net/bridge/bridge-nf-call-iptables
    write_sysctl 0 net/bridge/bridge-nf-call-ip6tables
    write_sysctl 0 net/bridge/bridge-nf-call-arptables
}

bridge_uplink_table() {
    table="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '
        NR == 1 {
            for (i = 1; i <= NF; i++) {
                if ($i == "table" && i < NF) { print $(i + 1); exit }
            }
        }
    ')"
    if [ -n "$table" ]; then
        echo "$table"
        return 0
    fi

    # Fallback for iproute2 variants that omit the selected table in `route
    # get`. Android normally exposes a named per-uplink default table.
    ip -4 route show table all 2>/dev/null | awk '
        $1 == "default" {
            dev=""
            table=""
            for (i = 1; i <= NF; i++) {
                if ($i == "dev" && i < NF) dev=$(i + 1)
                if ($i == "table" && i < NF) table=$(i + 1)
            }
            if (dev != "" && dev != "docker0" && table != "" &&
                table != "main" && table != "default") {
                print table
                exit
            }
        }
    '
}

prepare_bridge_policy_routes() {
    table="$(bridge_uplink_table)"
    subnet="$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' bridge 2>/dev/null)"

    case "$table" in
        ""|*[!A-Za-z0-9_.-]*)
            log "could not identify Android uplink routing table"
            return 1
            ;;
    esac
    case "$subnet" in
        ""|*[!0-9./]*)
            log "could not identify Docker bridge IPv4 subnet"
            return 1
            ;;
    esac

    iif_added=0
    return_added=0
    if ! ip rule show | grep -Fq "iif docker0 lookup $table"; then
        ip rule add iif docker0 lookup "$table" || return 1
        iif_added=1
    fi
    if ! ip rule show | grep -Fq "to $subnet lookup main"; then
        if ! ip rule add to "$subnet" lookup main; then
            [ "$iif_added" = 1 ] && ip rule del iif docker0 lookup "$table" 2>/dev/null || true
            return 1
        fi
        return_added=1
    fi

    # Replace the empty placeholders written by save_network_state. Recording
    # ownership lets stop remove only rules created by this runtime.
    sed -i \
        -e "s/^bridge_uplink_table=.*/bridge_uplink_table=$table/" \
        -e "s#^bridge_subnet=.*#bridge_subnet=$subnet#" \
        -e "s/^bridge_iif_added=.*/bridge_iif_added=$iif_added/" \
        -e "s/^bridge_return_added=.*/bridge_return_added=$return_added/" \
        "$NETWORK_STATE"
    log "installed Android policy routes for docker0 via table $table"
}

restore_network_state() {
    [ -f "$NETWORK_STATE" ] || return 0

    table=""
    subnet=""
    iif_added=0
    return_added=0

    while IFS='=' read -r name value; do
        case "$name" in
            ip_forward) write_sysctl "$value" net/ipv4/ip_forward ;;
            bridge_iptables) write_sysctl "$value" net/bridge/bridge-nf-call-iptables ;;
            bridge_ip6tables) write_sysctl "$value" net/bridge/bridge-nf-call-ip6tables ;;
            bridge_arptables) write_sysctl "$value" net/bridge/bridge-nf-call-arptables ;;
            bridge_uplink_table) table="$value" ;;
            bridge_subnet) subnet="$value" ;;
            bridge_iif_added) iif_added="$value" ;;
            bridge_return_added) return_added="$value" ;;
        esac
    done < "$NETWORK_STATE"

    if [ "$return_added" = 1 ] && [ -n "$subnet" ]; then
        ip rule del to "$subnet" lookup main 2>/dev/null || true
    fi
    if [ "$iif_added" = 1 ] && [ -n "$table" ]; then
        ip rule del iif docker0 lookup "$table" 2>/dev/null || true
    fi
    rm -f "$NETWORK_STATE"
}

ensure_host_shm() {
    mkdir -p /dev/shm
    if awk '$2 == "/dev/shm" { found=1 } END { exit !found }' /proc/mounts; then
        return 0
    fi
    mount -t tmpfs -o rw,nosuid,nodev,noexec,size=256m,mode=1777 tmpfs /dev/shm || \
        die "could not mount host /dev/shm"
    echo "owned" > "$RUN/shm.owned"
    log "mounted 256 MiB tmpfs at /dev/shm"
}

prepare_image() {
    mkdir -p "$DOCKER_ROOT" "$DOCKER_STATE" "$DOCKER_MOUNT" "$RUN" "$LOG"

    if [ ! -e "$DOCKER_IMAGE" ]; then
        target_bytes="$(size_to_bytes "$DOCKER_IMAGE_SIZE")" || \
            die "image size must be an integer from 2G through 512G"
        ensure_free_space "$target_bytes"
        log "creating $DOCKER_IMAGE_SIZE ext4 image at $DOCKER_IMAGE"
        truncate -s "$DOCKER_IMAGE_SIZE" "$DOCKER_IMAGE"
        if ! mkfs.ext4 -F -L docker-data -m 0 "$DOCKER_IMAGE" >"$LOG/mkfs.log" 2>&1; then
            rm -f "$DOCKER_IMAGE"
            die "mkfs.ext4 failed; see $LOG/mkfs.log"
        fi
    fi

    # Android's kernel loop thread cannot write ordinary /data file types.
    # vold_data_file is explicitly readable and writable by the kernel domain.
    chcon u:object_r:vold_data_file:s0 "$DOCKER_IMAGE" || \
        die "could not apply vold_data_file SELinux label"
}

size_to_bytes() {
    size="$1"
    case "$size" in
        [1-9]*G) ;;
        *) return 1 ;;
    esac
    gib="${size%G}"
    case "$gib" in
        *[!0-9]*|"") return 1 ;;
    esac
    [ "$gib" -ge 2 ] && [ "$gib" -le 512 ] || return 1
    echo $((gib * 1073741824))
}

ensure_free_space() {
    capacity_growth_bytes="$1"
    capacity_available_kib="$(df -Pk "$DOCKER_STATE" | awk 'NR == 2 { print $4 }')"
    capacity_required_kib=$(((capacity_growth_bytes + 1023) / 1024 + 262144))
    case "$capacity_available_kib" in
        *[!0-9]*|"") die "could not determine free storage" ;;
    esac
    [ "$capacity_available_kib" -ge "$capacity_required_kib" ] || \
        die "not enough free storage for the requested image plus the 256 MiB safety reserve"
}

resize_image() {
    target_size="$1"
    target_bytes="$(size_to_bytes "$target_size")" || \
        die "image size must be an integer from 2G through 512G"

    if [ ! -e "$DOCKER_IMAGE" ]; then
        DOCKER_IMAGE_SIZE="$target_size"
        prepare_image
        log "created a new $target_size Docker data image"
        return 0
    fi

    current_bytes="$(stat -c %s "$DOCKER_IMAGE" 2>/dev/null)" || \
        die "could not read the current image size"
    case "$current_bytes" in
        *[!0-9]*|"") die "invalid current image size: $current_bytes" ;;
    esac
    [ "$target_bytes" -ge "$current_bytes" ] || \
        die "shrinking is intentionally unsupported; create a new image instead"
    if [ "$target_bytes" -eq "$current_bytes" ]; then
        log "Docker data image is already $target_size"
        return 0
    fi

    was_running=0
    was_mounted=0
    daemon_running && was_running=1
    is_mounted && was_mounted=1

    growth_bytes=$((target_bytes - current_bytes))
    ensure_free_space "$growth_bytes"

    unmount_image

    log "growing Docker data image to $target_size"
    truncate -s "$target_size" "$DOCKER_IMAGE" || die "truncate failed"
    chcon u:object_r:vold_data_file:s0 "$DOCKER_IMAGE" || \
        die "could not restore the Docker image SELinux label"
    loop="$(losetup -f)" || die "no free loop device"
    losetup "$loop" "$DOCKER_IMAGE" || die "could not attach $DOCKER_IMAGE"

    e2fsck -pf "$loop" >"$LOG/e2fsck-resize.log" 2>&1
    fsck_rc=$?
    if [ "$fsck_rc" -gt 1 ]; then
        losetup -d "$loop" 2>/dev/null || true
        die "e2fsck failed with status $fsck_rc; see $LOG/e2fsck-resize.log"
    fi
    if ! resize2fs "$loop" >"$LOG/resize2fs.log" 2>&1; then
        losetup -d "$loop" 2>/dev/null || true
        die "resize2fs failed; see $LOG/resize2fs.log"
    fi
    losetup -d "$loop" || die "could not detach $loop after resize"

    if [ "$was_mounted" = 1 ] || [ "$was_running" = 1 ]; then
        mount_image
    fi
    if [ "$was_running" = 1 ]; then
        start_daemon
    fi
    log "Docker data image is now $target_size"
}

mount_image() {
    prepare_image

    if is_mounted; then
        log "already mounted: $DOCKER_MOUNT"
        return 0
    fi

    loop="$(image_loop)"
    if [ -z "$loop" ]; then
        loop="$(losetup -f)" || die "no free loop device"
        losetup "$loop" "$DOCKER_IMAGE" || die "could not attach $DOCKER_IMAGE"
    fi

    if ! mount -t ext4 -o noatime "$loop" "$DOCKER_MOUNT"; then
        losetup -d "$loop" 2>/dev/null || true
        die "could not mount $loop at $DOCKER_MOUNT"
    fi

    mkdir -p "$DATA_ROOT"
    echo "$loop" > "$RUN/data.loop"
    log "mounted $loop at $DOCKER_MOUNT"
}

stop_daemon() {
    if daemon_running; then
        pid="$(cat "$PIDFILE")"
        log "stopping dockerd pid $pid"
        kill "$pid" 2>/dev/null || true
        i=0
        while [ "$i" -lt 30 ] && kill -0 "$pid" 2>/dev/null; do
            sleep 0.5
            i=$((i + 1))
        done
        if kill -0 "$pid" 2>/dev/null; then
            log "dockerd did not exit after 15 seconds; sending SIGKILL"
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi

    # Managed containerd should exit with dockerd. Clean up only processes
    # whose executable resolves inside this project-local installation.
    for pid in $(pidof containerd 2>/dev/null); do
        exe="$(readlink "/proc/$pid/exe" 2>/dev/null)"
        case "$exe" in
            "$BIN/containerd") kill "$pid" 2>/dev/null || true ;;
        esac
    done

    cleanup_project_netns_mounts || true
    rm -f "$SOCKET" "$PIDFILE" "$RUN/launcher.pid"
    rm -rf "$RUN/docker"
    restore_network_state
    rm -f "$NETWORK_MODE_FILE"
}

start_daemon() {
    mount_image

    for name in docker dockerd containerd containerd-shim-runc-v2 runc docker-init; do
        require_binary "$name"
    done

    if daemon_running && docker info >/dev/null 2>&1; then
        log "dockerd is already ready"
        return 0
    fi

    stop_daemon
    mkdir -p "$RUN/docker" "$LOG" "$DATA_ROOT" "$SHIM_STATE"
    ensure_host_shm
    {
        echo "nameserver $DOCKER_DNS1"
        echo "nameserver $DOCKER_DNS2"
        echo "options timeout:2 attempts:2"
    } > "$DNS_FILE"
    chmod 0644 "$DNS_FILE"

    network_args="--iptables=false --ip6tables=false --bridge=none --ip-forward=false --ip-masq=false"
    case "$DOCKER_NETWORK_MODE" in
        isolated)
            ;;
        bridge|experimental-bridge)
            prepare_bridge_network
            network_args="--iptables=true --ip6tables=false --ip-forward=true --ip-masq=true"
            ;;
        *)
            die "DOCKER_NETWORK_MODE must be isolated or bridge"
            ;;
    esac
    echo "$DOCKER_NETWORK_MODE" > "$NETWORK_MODE_FILE"
    echo "$DOCKER_CGROUP_MODE" > "$RUN/cgroup.mode"

    log "starting Docker in $DOCKER_NETWORK_MODE network mode"
    # shellcheck disable=SC2086
    nohup unshare -m "$0" internal-daemon \
        --host "unix://$SOCKET" \
        --pidfile "$PIDFILE" \
        --data-root "$DATA_ROOT" \
        --exec-root "$RUN/docker" \
        --storage-driver overlay2 \
        --exec-opt native.cgroupdriver=cgroupfs \
        --default-cgroupns-mode=host \
        --dns "$DOCKER_DNS1" \
        --dns "$DOCKER_DNS2" \
        $network_args \
        >"$LOG/dockerd.log" 2>&1 </dev/null &
    echo "$!" > "$RUN/launcher.pid"

    i=0
    while [ "$i" -lt 60 ]; do
        if docker info >/dev/null 2>&1; then
            if [ "$DOCKER_NETWORK_MODE" = "bridge" ] ||
                [ "$DOCKER_NETWORK_MODE" = "experimental-bridge" ]; then
                # dockerd enables the bridge netfilter sysctls during network
                # initialization, so reapply the HyperOS workaround afterward.
                prepare_bridge_network
                if ! prepare_bridge_policy_routes; then
                    stop_daemon
                    die "could not install HyperOS bridge policy routes"
                fi
            fi
            log "Docker daemon is ready"
            return 0
        fi
        if [ -f "$RUN/launcher.pid" ]; then
            pid="$(cat "$RUN/launcher.pid")"
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
        fi
        sleep 0.5
        i=$((i + 1))
    done

    tail -100 "$LOG/dockerd.log" >&2
    restore_network_state
    rm -f "$NETWORK_MODE_FILE"
    die "Docker daemon did not become ready"
}

unmount_image() {
    stop_daemon

    if [ -f "$RUN/shm.owned" ]; then
        umount /dev/shm 2>/dev/null || true
        rmdir /dev/shm 2>/dev/null || true
        rm -f "$RUN/shm.owned"
    fi

    if is_mounted; then
        umount "$DOCKER_MOUNT" || die "could not unmount $DOCKER_MOUNT"
    fi

    loop="$(image_loop)"
    if [ -n "$loop" ]; then
        losetup -d "$loop" || die "could not detach $loop"
    fi
    rm -f "$RUN/data.loop"
    log "Docker data image is unmounted"
}

show_status() {
    echo "root=$DOCKER_ROOT"
    echo "image=$DOCKER_IMAGE"
    echo "mount=$DOCKER_MOUNT"
    if [ -f "$NETWORK_MODE_FILE" ]; then
        echo "network_mode=$(cat "$NETWORK_MODE_FILE")"
    else
        echo "network_mode=stopped"
    fi
    if [ -e "$DOCKER_IMAGE" ]; then
        echo "image_bytes=$(stat -c %s "$DOCKER_IMAGE" 2>/dev/null || echo unknown)"
        ls -lZ "$DOCKER_IMAGE"
    else
        echo "image_status=missing"
    fi
    if is_mounted; then
        echo "mount_status=mounted"
        df -h "$DOCKER_MOUNT"
    else
        echo "mount_status=unmounted"
    fi
    if daemon_running && docker info >/dev/null 2>&1; then
        echo "daemon_status=ready"
        docker version --format 'client={{.Client.Version}} server={{.Server.Version}}'
        docker info --format \
            'driver={{.Driver}} cgroup_driver={{.CgroupDriver}} cgroup_version={{.CgroupVersion}} containers={{.Containers}} images={{.Images}}'
    else
        echo "daemon_status=stopped"
    fi
}

destroy_data() {
    [ "${1:-}" = "--confirm-destroy" ] || \
        die "refusing destructive action; pass --confirm-destroy"
    unmount_image
    rm -f "$DOCKER_IMAGE"
    rm -rf "$DOCKER_MOUNT"
    log "removed Docker data image"
}

usage() {
    cat <<'EOF'
Usage: docker-runtime.sh COMMAND

Commands:
  prepare              Create and mount the ext4 data image
  mount                Mount an existing image, creating it if absent
  start                Start Docker (isolated network mode by default)
  stop                 Stop Docker but keep the data image mounted
  restart              Stop and start Docker
  status               Show image, mount and daemon state
  unmount              Stop Docker, unmount the image and detach its loop
  resize SIZE          Grow the ext4 image to SIZE (2G..512G, no shrinking)
  destroy --confirm-destroy
                       Permanently delete the Docker data image

Environment:
  DOCKER_IMAGE_SIZE=8G
  DOCKER_NETWORK_MODE=isolated|bridge
                       Isolated leaves Android networking untouched; use
                       --network host for those containers. Bridge installs
                       reversible policy rules for the active Android uplink.
  DOCKER_DNS1=223.5.5.5
  DOCKER_DNS2=1.1.1.1
EOF
}

require_root

case "${1:-}" in
    internal-daemon)
        shift
        run_daemon_in_mount_namespace "$@"
        ;;
    prepare|mount)
        mount_image
        ;;
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        start_daemon
        ;;
    status)
        show_status
        ;;
    unmount)
        unmount_image
        ;;
    resize)
        [ -n "${2:-}" ] || die "resize requires a target such as 16G"
        resize_image "$2"
        ;;
    destroy)
        destroy_data "${2:-}"
        ;;
    *)
        usage
        exit 2
        ;;
esac
