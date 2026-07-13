printf '\n---\n\n通过：%s  失败：%s  超时：%s  跳过：%s\n\n完成时间：%s\n' "$PASS_COUNT" "$FAIL_COUNT" "$TIMEOUT_COUNT" "$SKIP_COUNT" "$(date -Is)" >> "$REPORT";
echo LAVA_K1_BENCHMARK_REPORT_BEGIN;
cat "$INSTALL_REPORT";
echo;
cat "$REPORT";
echo;
cat "$METRIC_REPORT";
echo LAVA_K1_BENCHMARK_REPORT_END;
printf 'Report: %s\nMetrics: %s\nDetail: %s\nSuite results: %s\n' "$REPORT" "$METRIC_REPORT" "$DETAIL" "$SUITE_RESULTS";
printf 'LAVA Results 上报失败：%s\n' "$RESULT_SUBMIT_FAILURES";
printf 'LAVA_BENCHMARK_REPORT_%s\n' DONE
