#!/usr/bin/env bash
set -euo pipefail

mode="${1:?mode is required}"
sudo_run() { printf '%s\n' leetfs | sudo -S -p '' "$@"; }

case "$mode" in
  namespace)
    suffix="$$"
    ns="lava-ns-$suffix"
    a="lv${suffix}a"; b="lv${suffix}b"
    a="${a:0:15}"; b="${b:0:15}"
    cleanup() { sudo_run ip netns del "$ns" >/dev/null 2>&1 || true; sudo_run ip link del "$a" >/dev/null 2>&1 || true; }
    trap cleanup EXIT
    sudo_run ip netns add "$ns"
    sudo_run ip link add "$a" type veth peer name "$b"
    sudo_run ip link set "$b" netns "$ns"
    sudo_run ip addr add 192.0.2.1/30 dev "$a"
    sudo_run ip link set "$a" up
    sudo_run ip -n "$ns" addr add 192.0.2.2/30 dev "$b"
    sudo_run ip -n "$ns" link set lo up
    sudo_run ip -n "$ns" link set "$b" up
    sudo_run ip netns exec "$ns" ping -c 3 -W 2 192.0.2.1
    ;;
  iperf3)
    port=52037
    iperf3 -s -1 -p "$port" >"$WORK_DIR/iperf3-server.log" 2>&1 & server=$!
    trap 'kill "$server" 2>/dev/null || true' EXIT
    sleep 1
    iperf3 -c 127.0.0.1 -p "$port" -t 5
    wait "$server"
    ;;
  netperf)
    netserver -p 12867 >"$WORK_DIR/netserver.log" 2>&1 & server=$!
    trap 'kill "$server" 2>/dev/null || true' EXIT
    sleep 1
    netperf -H 127.0.0.1 -p 12867 -l 5 -t TCP_STREAM
    ;;
  sockperf)
    sockperf server -i 127.0.0.1 -p 12345 >"$WORK_DIR/sockperf-server.log" 2>&1 & server=$!
    trap 'kill "$server" 2>/dev/null || true' EXIT
    sleep 1
    sockperf ping-pong -i 127.0.0.1 -p 12345 -t 5
    ;;
  qperf)
    qperf >"$WORK_DIR/qperf-server.log" 2>&1 & server=$!
    trap 'kill "$server" 2>/dev/null || true' EXIT
    sleep 1
    qperf 127.0.0.1 tcp_bw tcp_lat
    ;;
  *) exit 2 ;;
esac
