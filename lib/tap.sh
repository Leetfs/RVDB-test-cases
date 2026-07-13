report_tap_results() {
  tap_file="$1"
  tap_prefix="$2"
  [ -s "$tap_file" ] || return 0

  tap_parsed="$WORK_DIR/tap-$(metric_slug "$tap_prefix")-$$.txt"
  awk '
    {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      if (line !~ /^(not )?ok[[:space:]]+[0-9]+/) next
      result=(line ~ /^not ok/) ? "fail" : "pass"
      skip=(toupper(line) ~ /#[[:space:]]*SKIP/) ? "skip" : result
      sub(/^(not )?ok[[:space:]]+/, "", line)
      number=line; sub(/[[:space:]].*$/, "", number)
      name=line; sub(/^[0-9]+[[:space:]]*-?[[:space:]]*/, "", name); sub(/[[:space:]]*#.*/, "", name)
      if (name == "") name="case"
      sequence++
      print sequence "|" name "|" skip
    }
  ' "$tap_file" > "$tap_parsed"
  while IFS='|' read -r tap_number tap_name tap_status; do
    case_id="$(metric_slug "$tap_prefix-$tap_number-$tap_name")"
    [ -n "$case_id" ] || continue
    printf 'LAVA_TAP_RESULT %s=%s\n' "$case_id" "$tap_status" | tee -a "$DETAIL" "$SUITE_RESULTS"
    lava_result "$case_id" --result "$tap_status"
  done < "$tap_parsed"
}
