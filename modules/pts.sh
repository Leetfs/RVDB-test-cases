if [ "$RUN_PTS" -eq 1 ] && [ -n "$PTS_TESTS" ]; then
  mkdir -p "$WORK_DIR/pts-user" "$WORK_DIR/pts-tests" "$WORK_DIR/pts-json"
  pts_unsupported="$(timeout 5m env PTS_USER_PATH_OVERRIDE="$WORK_DIR/pts-user/" \
    PTS_TEST_INSTALL_ROOT_PATH="$WORK_DIR/pts-tests/" \
    phoronix-test-suite list-unsupported-tests 2>/dev/null || true)"
  for pts_test in $PTS_TESTS; do
    pts_case="${pts_test##*/}"
    printf -v pts_test_quoted '%q' "$pts_test"
    if printf '%s\n' "$pts_unsupported" | grep -Fq "$pts_test"; then
      record_skip pts "$pts_case" 'profile does not support this OS or CPU architecture'
      continue
    fi
    if ! timeout 5m env PTS_USER_PATH_OVERRIDE="$WORK_DIR/pts-user/" \
      PTS_TEST_INSTALL_ROOT_PATH="$WORK_DIR/pts-tests/" \
      phoronix-test-suite info "$pts_test" >/dev/null 2>&1; then
      record_skip pts "$pts_case" 'profile is unavailable for this PTS repository/platform'
      continue
    fi
    pts_result_name="lava-$RUN_ID-$pts_case"
    pts_json_file="$WORK_DIR/pts-json/$pts_case.json"
    pts_metrics_file="$WORK_DIR/pts-json/$pts_case.tsv"
    run_cmd pts "$pts_case" "$PTS_TEST_TIMEOUT" 'command -v phoronix-test-suite' \
      "env PTS_USER_PATH_OVERRIDE=\"$WORK_DIR/pts-user/\" PTS_TEST_INSTALL_ROOT_PATH=\"$WORK_DIR/pts-tests/\" FORCE_TIMES_TO_RUN=\"$PTS_TIMES_TO_RUN\" REMOVE_TESTS_ON_COMPLETION=1 TEST_RESULTS_NAME=\"$pts_result_name\" TEST_RESULTS_DESCRIPTION=\"LAVA Job $RUN_ID\" phoronix-test-suite default-benchmark $pts_test_quoted && env PTS_USER_PATH_OVERRIDE=\"$WORK_DIR/pts-user/\" OUTPUT_FILE=\"$pts_json_file\" phoronix-test-suite result-file-to-json \"$pts_result_name\" && python3 \"$ROOT_DIR/scripts/pts-json-metrics.py\" \"$pts_json_file\" \"$pts_case\" > \"$pts_metrics_file\""
    if [ "$status" = PASS ]; then
      report_pts_metrics "$pts_metrics_file"
    fi
  done
else
  record_skip pts phoronix-test-suite 'set RUN_PTS=1 and PTS_TESTS'
fi

printf 'LAVA_PTS_BENCHMARKS_%s\n' DONE
