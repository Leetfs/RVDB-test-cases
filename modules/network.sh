if [ "$RUN_NETWORK" -eq 1 ]; then
  run_cmd network ipv4-loopback 5m 'command -v ping' 'ping -c 5 -W 2 127.0.0.1'
  run_cmd network ipv6-loopback 5m 'command -v ping && test -r /proc/net/if_inet6' 'ping -6 -c 5 -W 2 ::1'
  run_cmd network route-address 5m 'command -v ip' 'ip -details address show; ip route show table all; ip -6 route show table all'
  run_cmd network namespace-veth 10m 'command -v ip && command -v ping && printf "%s\n" leetfs | sudo -S -p "" -v' 'bash "$ROOT_DIR/scripts/network-smoke.sh" namespace'
  run_cmd network iperf3-loopback 15m 'command -v iperf3' 'bash "$ROOT_DIR/scripts/network-smoke.sh" iperf3'
  run_cmd network netperf-loopback 15m 'command -v netperf && command -v netserver' 'bash "$ROOT_DIR/scripts/network-smoke.sh" netperf'
  run_cmd network sockperf-loopback 15m 'command -v sockperf' 'bash "$ROOT_DIR/scripts/network-smoke.sh" sockperf'
  run_cmd network qperf-loopback 15m 'command -v qperf' 'bash "$ROOT_DIR/scripts/network-smoke.sh" qperf'
  run_cmd network ethtool 5m 'command -v ethtool && find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -print -quit | grep -q .' 'for n in /sys/class/net/*; do i=${n##*/}; test "$i" = lo && continue; ethtool "$i" || true; ethtool -k "$i" || true; done'
else
  for test_name in ipv4-loopback ipv6-loopback route-address namespace-veth iperf3-loopback netperf-loopback sockperf-loopback qperf-loopback ethtool; do record_skip network "$test_name" 'RUN_NETWORK=0'; done
fi
