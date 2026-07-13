if [ "$RUN_DISTRO" -eq 1 ]; then
  run_cmd distro package-database 10m 'command -v dpkg || command -v rpm' 'if command -v dpkg >/dev/null; then dpkg --audit; else rpm -qa >/dev/null && rpm --verifydb; fi'
  run_cmd distro dynamic-linker-cache 5m 'command -v ldconfig' 'ldconfig -p'
  run_cmd distro systemd-failed-units 5m 'command -v systemctl && test -d /run/systemd/system' 'failed=$(systemctl --failed --no-legend --plain); printf "%s\n" "$failed"; test -z "$failed"'
  run_cmd distro systemd-boot-analysis 5m 'command -v systemd-analyze && test -d /run/systemd/system' 'systemd-analyze time; systemd-analyze blame | head -50; systemd-analyze critical-chain'
  run_cmd distro locale-database 5m 'command -v locale' 'locale; locale -a'
  run_cmd distro time-configuration 5m 'command -v timedatectl && test -d /run/systemd/system' 'timedatectl show --all'
  run_cmd distro cgroup-layout 5m 'test -d /sys/fs/cgroup' 'stat -fc "type=%T" /sys/fs/cgroup; findmnt /sys/fs/cgroup; test ! -r /sys/fs/cgroup/cgroup.controllers || cat /sys/fs/cgroup/cgroup.controllers'
  run_cmd distro mount-layout 5m 'command -v findmnt' 'findmnt --real --output TARGET,SOURCE,FSTYPE,OPTIONS'
else
  for test_name in package-database dynamic-linker-cache systemd-failed-units systemd-boot-analysis locale-database time-configuration cgroup-layout mount-layout; do record_skip distro "$test_name" 'RUN_DISTRO=0'; done
fi
