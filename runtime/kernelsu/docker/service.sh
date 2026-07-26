#!/system/bin/sh

MODDIR=${0%/*}
CONTROL="$MODDIR/scripts/control.sh"
LOG=/data/local/docker/logs/kernelsu-service.log

mkdir -p "${LOG%/*}"
exec >>"$LOG" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') waiting for Android data"
i=0
while [ "$i" -lt 120 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && [ -d /data/unencrypted ] && break
    sleep 2
    i=$((i + 1))
done

[ -x "$CONTROL" ] || {
    echo "control script missing: $CONTROL"
    exit 1
}

auto_start="$($CONTROL get AUTO_START 2>/dev/null)" || exit 1
[ "$auto_start" = 1 ] || {
    echo "automatic startup is disabled"
    exit 0
}

exec "$CONTROL" start
