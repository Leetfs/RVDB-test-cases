RUN_ID="${LAVA_JOB_ID:-$$}"
WORK_DIR="/tmp/lava-k1-benchmark-$RUN_ID"
SOURCE_ROOT="$WORK_DIR/source"
SPEC_WORK_ROOT="$WORK_DIR/spec"
STORAGE_FIO_FILE="$WORK_DIR/fio.bin"
STORAGE_IOZONE_FILE="$WORK_DIR/iozone.bin"
OVERLAY_DIR="/home/leetfs/lava-$RUN_ID"
CLEANUP_DONE=0

cleanup_path() {
  path="$1"
  [ -e "$path" ] || return 0
  rm -rf -- "$path" 2>/dev/null || \
    printf '%s\n' leetfs | sudo -S -p '' rm -rf -- "$path" 2>/dev/null || true
}

cleanup_artifacts() {
  [ "$CLEANUP_DONE" -eq 0 ] || return 0
  CLEANUP_DONE=1
  if [ -d "$SPEC_WORK_ROOT" ]; then
    find "$SPEC_WORK_ROOT" -type d -name mount -print 2>/dev/null | while read -r mount_dir; do
      if mountpoint -q "$mount_dir" 2>/dev/null; then
        printf '%s\n' leetfs | sudo -S -p '' umount "$mount_dir" >/dev/null 2>&1 || true
      fi
    done
  fi
  cleanup_path "$WORK_DIR"
  stty echo 2>/dev/null || true
}

handle_cleanup_signal() {
  signal_rc="$1"
  trap - EXIT HUP INT TERM
  cleanup_artifacts
  exit "$signal_rc"
}

cleanup_stale_artifacts() {
  for stale in /tmp/lava-k1-benchmark-* /tmp/lava-src /tmp/lava-cargo \
    /tmp/lava-spec2017-install /tmp/lava-fio.bin /tmp/lava-iozone.bin; do
    [ -e "$stale" ] || continue
    if [ -d "$stale" ]; then
      find "$stale" -type d -name mount -print 2>/dev/null | while read -r mount_dir; do
        mountpoint -q "$mount_dir" 2>/dev/null || continue
        printf '%s\n' leetfs | sudo -S -p '' umount "$mount_dir" >/dev/null 2>&1 || true
      done
    fi
    cleanup_path "$stale"
  done
  for stale_overlay in /home/leetfs/lava-*; do
    [ -e "$stale_overlay" ] || continue
    [ "$stale_overlay" = "$OVERLAY_DIR" ] && continue
    cleanup_path "$stale_overlay"
  done
}

cleanup_stale_artifacts
mkdir -p "$SOURCE_ROOT" "$SPEC_WORK_ROOT"
export RUN_ID WORK_DIR SOURCE_ROOT SPEC_WORK_ROOT STORAGE_FIO_FILE STORAGE_IOZONE_FILE OVERLAY_DIR

trap 'rc=$?; cleanup_artifacts; exit "$rc"' EXIT
trap 'handle_cleanup_signal 129' HUP
trap 'handle_cleanup_signal 130' INT
trap 'handle_cleanup_signal 143' TERM

# LAVA 取消任务时可能直接结束测试 shell；独立会话守护进程会在父进程消失后兜底清理。
nohup setsid bash -c '
  parent="$1"; work_dir="$2"; overlay_dir="$3"
  while kill -0 "$parent" 2>/dev/null; do sleep 2; done
  if [ -d "$work_dir/spec" ]; then
    find "$work_dir/spec" -type d -name mount -print 2>/dev/null | while read -r mount_dir; do
      mountpoint -q "$mount_dir" 2>/dev/null || continue
      printf "%s\n" leetfs | sudo -S -p "" umount "$mount_dir" >/dev/null 2>&1 || true
    done
  fi
  rm -rf -- "$work_dir" 2>/dev/null || \
    printf "%s\n" leetfs | sudo -S -p "" rm -rf -- "$work_dir" >/dev/null 2>&1 || true
  # LAVA runner may still consume files briefly after run-profile exits.
  sleep 30
  rm -rf -- "$overlay_dir" 2>/dev/null || \
    printf "%s\n" leetfs | sudo -S -p "" rm -rf -- "$overlay_dir" >/dev/null 2>&1 || true
' cleanup-guardian "$$" "$WORK_DIR" "$OVERLAY_DIR" >/dev/null 2>&1 &
