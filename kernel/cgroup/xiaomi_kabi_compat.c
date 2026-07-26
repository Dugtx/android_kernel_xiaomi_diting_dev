// SPDX-License-Identifier: GPL-2.0
/*
 * Xiaomi cgroup kABI compatibility symbols.
 *
 * The diting vendor modules were built against a GKI kernel that exports the
 * legacy freezer controller.  The device compatibility profile reuses that
 * unused runtime controller slot for the cgroup v1 devices controller, but the
 * exported freezer symbol must remain available to preserve the stock KMI.
 *
 * This zero-initialized descriptor is deliberately not present in the runtime
 * cgroup subsystem table.  It exists only as a type-compatible KMI anchor.
 */

#include <linux/cgroup.h>
#include <linux/export.h>

struct cgroup_subsys freezer_cgrp_subsys;
EXPORT_SYMBOL_GPL(freezer_cgrp_subsys);
