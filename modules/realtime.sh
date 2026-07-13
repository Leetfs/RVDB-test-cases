if [ "$RUN_REALTIME" -eq 1 ]; then
  run_cmd realtime cyclictest 15m 'command -v cyclictest && printf "%s\n" leetfs | sudo -S -p "" -v' "printf '%s\\n' leetfs | sudo -S -p '' cyclictest --mlockall --smp --priority=80 --interval=1000 --duration=${REALTIME_SECONDS}s"
  run_cmd realtime hackbench 15m 'command -v perf' 'perf bench sched messaging -g 10 -l 1000'
  run_cmd realtime oslat 15m 'command -v oslat && printf "%s\n" leetfs | sudo -S -p "" -v' "printf '%s\\n' leetfs | sudo -S -p '' oslat -D $REALTIME_SECONDS -q"
  run_cmd realtime hwlatdetect 15m 'command -v hwlatdetect && printf "%s\n" leetfs | sudo -S -p "" -v' "printf '%s\\n' leetfs | sudo -S -p '' hwlatdetect --duration=$REALTIME_SECONDS --threshold=1000"
else
  for test_name in cyclictest hackbench oslat hwlatdetect; do record_skip realtime "$test_name" 'RUN_REALTIME=0'; done
fi
