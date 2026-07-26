#!/system/bin/sh

MODDIR=${0%/*}
[ -x "$MODDIR/scripts/control.sh" ] && \
    "$MODDIR/scripts/control.sh" unmount >/dev/null 2>&1 || true

# Container images, the ext4 data image, configuration, and logs are retained.
# Deleting persistent data is intentionally an explicit manual operation.
exit 0
