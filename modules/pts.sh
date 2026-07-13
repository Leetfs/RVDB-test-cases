if [ "$RUN_PTS" -eq 1 ] && [ -n "$PTS_TESTS" ]; then
  mkdir -p "$WORK_DIR/pts-user" "$WORK_DIR/pts-tests"
  for pts_test in $PTS_TESTS; do
    pts_case="${pts_test##*/}"
    printf -v pts_test_quoted '%q' "$pts_test"
    run_cmd pts "$pts_case" 4h 'command -v phoronix-test-suite' \
      "env PTS_USER_PATH_OVERRIDE=\"$WORK_DIR/pts-user/\" PTS_TEST_INSTALL_ROOT_PATH=\"$WORK_DIR/pts-tests/\" NO_EXTERNAL_DEPENDENCIES=1 FORCE_TIMES_TO_RUN=1 REMOVE_TESTS_ON_COMPLETION=1 TEST_RESULTS_NAME=\"lava-$RUN_ID-$pts_case\" TEST_RESULTS_DESCRIPTION=\"LAVA Job $RUN_ID\" phoronix-test-suite default-benchmark $pts_test_quoted"
  done
else
  record_skip pts phoronix-test-suite 'set RUN_PTS=1 and PTS_TESTS'
fi

printf 'LAVA_PTS_BENCHMARKS_%s\n' DONE
