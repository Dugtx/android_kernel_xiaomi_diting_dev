#!/system/bin/sh

MODDIR=${0%/*}
exec "$MODDIR/scripts/control.sh" status
