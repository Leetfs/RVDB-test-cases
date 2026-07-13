printf 'LAVA_BENCHMARK_ALL_%s\n' DONE;
stty echo
if [ "$RESULT_SUBMIT_FAILURES" -ne 0 ]; then
  printf 'ERROR: %s LAVA Results entries could not be submitted\n' "$RESULT_SUBMIT_FAILURES" >&2
  exit 4
fi
if [ "$STRICT" -eq 1 ] && { [ "$FAIL_COUNT" -ne 0 ] || [ "$TIMEOUT_COUNT" -ne 0 ]; }; then
  exit 1
fi
