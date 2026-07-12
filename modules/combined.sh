run_cmd combined byte-unixbench 2h 'command -v byte-unixbench || test -x /usr/lib/byte-unixbench/Run' 'if command -v byte-unixbench >/dev/null; then byte-unixbench; else cd /usr/lib/byte-unixbench && ./Run; fi';
run_cmd combined lmbench-lat-syscall 30m 'command -v lat_syscall || ls /usr/lib/lmbench/bin/*/lat_syscall >/dev/null 2>&1' 'if command -v lat_syscall >/dev/null; then lat_syscall null; else /usr/lib/lmbench/bin/*/lat_syscall null; fi';
run_cmd combined lmbench-lat-mem-rd 30m 'command -v lat_mem_rd || ls /usr/lib/lmbench/bin/*/lat_mem_rd >/dev/null 2>&1' 'if command -v lat_mem_rd >/dev/null; then lat_mem_rd 512M 128; else /usr/lib/lmbench/bin/*/lat_mem_rd 512M 128; fi';
run_cmd combined sbc-bench 2h 'command -v sbc-bench || test -x /opt/sbc-bench/sbc-bench.sh' 'if command -v sbc-bench >/dev/null; then sbc-bench; else /opt/sbc-bench/sbc-bench.sh; fi';
if [ "$RUN_PTS" -eq 1 ] && [ -n "$PTS_TESTS" ]; then run_cmd combined phoronix-test-suite 12h 'command -v phoronix-test-suite' "phoronix-test-suite batch-run $PTS_TESTS"; else record_skip combined phoronix-test-suite 'set RUN_PTS=1 and PTS_TESTS'; fi;
printf 'LAVA_COMBINED_BENCHMARKS_%s\n' DONE
