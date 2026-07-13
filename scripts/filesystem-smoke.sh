#!/usr/bin/env bash
set -euo pipefail

mode="${1:?mode is required}"
base="${WORK_DIR:?WORK_DIR is required}/filesystem-$mode"
mkdir -p "$base"
sudo_run() { printf '%s\n' leetfs | sudo -S -p '' "$@"; }

case "$mode" in
  tmpfs)
    mkdir -p "$base/mnt"
    trap 'sudo_run umount "$base/mnt" >/dev/null 2>&1 || true' EXIT
    sudo_run mount -t tmpfs -o size=64m tmpfs "$base/mnt"
    dd if=/dev/zero of="$base/mnt/data" bs=1M count=16 status=none
    sync
    test "$(stat -fc %T "$base/mnt")" = tmpfs
    ;;
  overlayfs)
    mkdir -p "$base/lower" "$base/upper" "$base/work" "$base/merged"
    printf 'lower\n' > "$base/lower/source"
    trap 'sudo_run umount "$base/merged" >/dev/null 2>&1 || true' EXIT
    sudo_run mount -t overlay overlay -o "lowerdir=$base/lower,upperdir=$base/upper,workdir=$base/work" "$base/merged"
    test "$(cat "$base/merged/source")" = lower
    printf 'upper\n' > "$base/merged/source"
    test "$(cat "$base/upper/source")" = upper
    ;;
  *) exit 2 ;;
esac
