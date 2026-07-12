run_cmd ram tinymembench 30m 'command -v tinymembench' 'tinymembench';
run_cmd ram ramlat 30m 'command -v ramlat' 'ramlat';
run_cmd ram core-to-core-latency 30m 'command -v core-to-core-latency' 'core-to-core-latency';
run_cmd ram stream 30m 'command -v stream' 'stream';
printf 'LAVA_MEMORY_BENCHMARKS_%s\n' DONE
