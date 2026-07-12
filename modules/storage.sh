if [ "$RUN_STORAGE" -eq 1 ]; then
  run_cmd storage fio 2h 'command -v fio' 'fio --name=lava-k1 --filename=/tmp/lava-fio.bin --size='"$STORAGE_SIZE"' --direct=1 --ioengine=libaio --iodepth=32 --rw=randrw --rwmixread=70 --bs=4k --runtime=120 --time_based --group_reporting; rc=$?; rm -f /tmp/lava-fio.bin; exit $rc';
  run_cmd storage iozone 2h 'command -v iozone' 'iozone -a -s '"$STORAGE_SIZE"' -r 4k -i 0 -i 1 -f /tmp/lava-iozone.bin; rc=$?; rm -f /tmp/lava-iozone.bin; exit $rc';
else
  record_skip storage fio 'RUN_STORAGE=0';
  record_skip storage iozone 'RUN_STORAGE=0';
fi;
printf 'LAVA_STORAGE_BENCHMARKS_%s\n' DONE
