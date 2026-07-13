if [ "$RUN_KSELFTEST" -eq 1 ]; then
  run_cmd kernel kselftest 12h 'test -x /opt/kselftest/run_kselftest.sh || test -x /usr/lib/linux-kselftests/run_kselftest.sh' "runner=/opt/kselftest/run_kselftest.sh; test -x \"\$runner\" || runner=/usr/lib/linux-kselftests/run_kselftest.sh; rc=0; for c in $KSELFTEST_COLLECTIONS; do printf '%s\\n' leetfs | sudo -S -p '' \"\$runner\" -c \"\$c\" || rc=1; done; exit \"\$rc\""
  report_tap_results "$output_file" kernel-kselftest
else
  record_skip kernel kselftest 'RUN_KSELFTEST=0'
fi
run_cmd kernel kunit-results 10m 'find /sys/kernel/debug/kunit -type f -name results -print -quit 2>/dev/null | grep -q .' 'rc=0; for f in /sys/kernel/debug/kunit/*/results; do cat "$f"; grep -Eq "not ok|Bail out!" "$f" && rc=1; done; exit "$rc"'
report_tap_results "$output_file" kernel-kunit
run_cmd kernel perf-bench 30m 'command -v perf' 'perf bench all'
run_cmd kernel bpf-features 10m 'command -v bpftool && printf "%s\n" leetfs | sudo -S -p "" -v' 'printf "%s\n" leetfs | sudo -S -p "" bpftool feature probe'
