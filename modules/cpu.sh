run_cmd cpu coremark 20m 'command -v coremark' 'coremark';
run_cmd cpu coremark-pro 2h 'command -v coremark-pro || test -x /opt/coremark-pro/coremark-pro' 'if command -v coremark-pro >/dev/null; then coremark-pro; else /opt/coremark-pro/coremark-pro; fi';
run_cmd cpu unixbench 2h 'command -v byte-unixbench || command -v Run || test -x /usr/lib/byte-unixbench/Run || test -x /opt/UnixBench/Run' 'if command -v byte-unixbench >/dev/null; then byte-unixbench; elif command -v Run >/dev/null; then Run; elif test -x /usr/lib/byte-unixbench/Run; then cd /usr/lib/byte-unixbench && ./Run; else cd /opt/UnixBench && ./Run; fi';
run_cmd cpu openssl-aes 15m 'command -v openssl' 'openssl speed -elapsed -seconds 3 aes-128-cbc aes-256-cbc && openssl speed -elapsed -seconds 3 -evp aes-128-gcm && openssl speed -elapsed -seconds 3 -evp aes-256-gcm';
run_cmd cpu openssl-chacha20 10m 'command -v openssl' 'openssl speed -elapsed -seconds 3 -evp chacha20-poly1305';
run_cmd cpu openssl-sm2 10m 'command -v openssl' 'openssl speed -elapsed -seconds 3 sm2';
run_cmd cpu openssl-sm3-sm4 10m 'command -v openssl' 'openssl speed -elapsed -seconds 3 -evp sm3 && openssl speed -elapsed -seconds 3 -evp sm4-cbc';
run_cmd cpu 7zip 30m 'command -v 7z' '7z b';
run_cmd cpu stockfish 30m 'command -v stockfish || test -x /usr/games/stockfish' 'if command -v stockfish >/dev/null; then printf "bench\\nquit\\n" | stockfish; else printf "bench\\nquit\\n" | /usr/games/stockfish; fi';
if [ "$RUN_SPEC" -eq 1 ] && [ -n "$SPEC2017_CMD" ]; then run_cmd cpu spec-cpu2017 12h 'test -n "$SPEC2017_CMD"' "$SPEC2017_CMD"; else record_skip cpu spec-cpu2017 'SPEC CPU 2017 is disabled or automatic initialization failed'; fi;
printf 'LAVA_CPU_BENCHMARKS_%s\n' DONE
