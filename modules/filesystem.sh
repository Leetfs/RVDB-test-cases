if [ "$RUN_FILESYSTEM" -eq 1 ]; then
  run_cmd filesystem tmpfs 10m 'command -v mount && printf "%s\n" leetfs | sudo -S -p "" -v' 'bash "$ROOT_DIR/scripts/filesystem-smoke.sh" tmpfs'
  run_cmd filesystem overlayfs 10m 'grep -qw overlay /proc/filesystems && printf "%s\n" leetfs | sudo -S -p "" -v' 'bash "$ROOT_DIR/scripts/filesystem-smoke.sh" overlayfs'
  run_cmd filesystem fsx 30m 'command -v fsx || test -x /opt/xfstests/src/fsx' 'if command -v fsx >/dev/null; then fsx "$WORK_DIR/fsx-file"; else /opt/xfstests/src/fsx "$WORK_DIR/fsx-file"; fi'
  run_cmd filesystem pjdfstest 30m 'command -v pjdfstest || test -x /opt/pjdfstest/pjdfstest' 'if command -v pjdfstest >/dev/null; then pjdfstest; else cd /opt/pjdfstest && prove -r tests; fi'
  if [ "$RUN_DESTRUCTIVE" -eq 1 ] && [ -n "$XFSTESTS_TEST_DEV" ] && [ -n "$XFSTESTS_SCRATCH_DEV" ]; then
    run_cmd filesystem xfstests 12h 'test -x /opt/xfstests/check' "cd /opt/xfstests && printf '%s\\n' leetfs | sudo -S -p '' env TEST_DEV=\"$XFSTESTS_TEST_DEV\" SCRATCH_DEV=\"$XFSTESTS_SCRATCH_DEV\" ./check -g quick"
  else
    record_skip filesystem xfstests 'requires RUN_DESTRUCTIVE=1 and dedicated TEST/SCRATCH devices'
  fi
  if [ "$RUN_DESTRUCTIVE" -eq 1 ] && [ -n "$BLKTESTS_DEVICES" ]; then
    run_cmd storage blktests 12h 'test -x /opt/blktests/check' "cd /opt/blktests && printf '%s\\n' leetfs | sudo -S -p '' env TEST_DEVS=\"$BLKTESTS_DEVICES\" ./check"
  else
    record_skip storage blktests 'requires RUN_DESTRUCTIVE=1 and BLKTESTS_DEVICES'
  fi
else
  for test_name in tmpfs overlayfs fsx pjdfstest xfstests blktests; do record_skip filesystem "$test_name" 'RUN_FILESYSTEM=0'; done
fi
