#!/system/bin/sh

ui_print "- Docker Runtime for Redmi K50 Ultra"

device="$(getprop ro.product.device)"
[ "$device" = "diting" ] || abort "This module supports diting only; detected: $device"
[ -x "$MODPATH/bin/dockerd" ] || abort "The module package is incomplete: dockerd is missing"
[ -x "$MODPATH/bin/docker" ] || abort "The module package is incomplete: docker is missing"

STATE=/data/unencrypted/docker
mkdir -p "$STATE/config"
if [ ! -e "$STATE/runtime.conf" ]; then
    cp "$MODPATH/runtime.conf.example" "$STATE/runtime.conf" || \
        abort "Could not create $STATE/runtime.conf"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/module.prop" 0 0 0644
set_perm "$MODPATH/runtime.conf.example" 0 0 0644
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
set_perm "$STATE" 0 0 0755
set_perm "$STATE/config" 0 0 0755
set_perm "$STATE/runtime.conf" 0 0 0644

ui_print "- Configuration: $STATE/runtime.conf"
ui_print "- Data image: $STATE/data.ext4 (created on first start)"
ui_print "- Default profile: cgroup v2, isolated network, 8 GiB"
ui_print "- Reboot, then open the module WebUI to start or configure Docker"
