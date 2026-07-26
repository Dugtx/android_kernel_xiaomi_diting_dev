#!/usr/bin/env bash

set -euo pipefail

range="${1:-}"
[ -n "$range" ] || {
    echo "usage: $0 REVISION_RANGE" >&2
    exit 2
}

failures=0
while IFS= read -r commit; do
    [ -n "$commit" ] || continue
    parents="$(git show -s --format='%P' "$commit")"
    # Merge commits carry no new patch authorship; check their constituent
    # commits instead.
    case "$parents" in *" "*) continue ;; esac

    author_name="$(git show -s --format='%an' "$commit")"
    author_email="$(git show -s --format='%ae' "$commit")"
    if ! git show -s --format='%B' "$commit" | \
        grep -Eiq '^Signed-off-by:[[:space:]]+.+[[:space:]]+<[^>]+>[[:space:]]*$'; then
        echo "DCO sign-off missing: $commit ($author_name <$author_email>)" >&2
        failures=1
    fi
done < <(git rev-list --reverse "$range")

[ "$failures" -eq 0 ] || exit 1
echo "DCO sign-off check passed for $range"
