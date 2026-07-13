if [ "$RUN_SECURITY" -eq 1 ]; then
  run_cmd security seccomp-status 5m 'test -r /proc/self/status' 'grep -E "^(NoNewPrivs|Seccomp|Seccomp_filters|Cap(Inh|Prm|Eff|Bnd|Amb)):" /proc/self/status'
  run_cmd security capabilities 5m 'command -v capsh' 'capsh --print'
  run_cmd security userns 5m 'command -v unshare' 'unshare -Ur true'
  run_cmd security lsm-status 5m 'test -r /sys/kernel/security/lsm || test -r /sys/module/apparmor/parameters/enabled || test -d /sys/fs/selinux' 'test ! -r /sys/kernel/security/lsm || cat /sys/kernel/security/lsm; test ! -r /sys/module/apparmor/parameters/enabled || cat /sys/module/apparmor/parameters/enabled; test ! -r /sys/fs/selinux/enforce || cat /sys/fs/selinux/enforce'
  run_cmd security audit-status 5m 'command -v auditctl && printf "%s\n" leetfs | sudo -S -p "" -v' 'printf "%s\n" leetfs | sudo -S -p "" auditctl -s'
  run_cmd security kernel-hardening 10m 'command -v checksec' 'checksec --kernel'
  run_cmd security lynis 30m 'command -v lynis && printf "%s\n" leetfs | sudo -S -p "" -v' 'printf "%s\n" leetfs | sudo -S -p "" lynis audit system --quick --no-colors --pentest'
  if [ "$RUN_OPENSCAP" -eq 1 ] && [ -n "$OPENSCAP_CONTENT" ] && [ -n "$OPENSCAP_PROFILE" ]; then
    run_cmd security openscap 2h 'command -v oscap && test -r "$OPENSCAP_CONTENT"' "printf '%s\\n' leetfs | sudo -S -p '' oscap xccdf eval --profile \"$OPENSCAP_PROFILE\" --results \"$WORK_DIR/openscap-results.xml\" --report \"$WORK_DIR/openscap-report.html\" \"$OPENSCAP_CONTENT\""
  else
    record_skip security openscap 'set RUN_OPENSCAP=1, OPENSCAP_CONTENT and OPENSCAP_PROFILE'
  fi
else
  for test_name in seccomp-status capabilities userns lsm-status audit-status kernel-hardening lynis openscap; do record_skip security "$test_name" 'RUN_SECURITY=0'; done
fi
