run_cmd virtualization kvm-unit-tests 4h 'test -e /dev/kvm && (test -x /opt/kvm-unit-tests/run_tests.sh || test -x /usr/share/kvm-unit-tests/run_tests.sh)' 'if test -x /opt/kvm-unit-tests/run_tests.sh; then cd /opt/kvm-unit-tests && ./run_tests.sh; else cd /usr/share/kvm-unit-tests && ./run_tests.sh; fi';
if [ "$RUN_LTP" -eq 1 ]; then run_cmd kernel ltp 12h 'command -v runltp || test -x /opt/ltp/runltp' 'if command -v runltp >/dev/null; then runltp -f syscalls; else /opt/ltp/runltp -f syscalls; fi'; else record_skip kernel ltp 'set RUN_LTP=1'; fi;
printf 'LAVA_VIRT_KERNEL_%s\n' DONE
