pts_tier_rank() {
  case "$1" in
    smoke) printf '1\n' ;;
    standard) printf '2\n' ;;
    extended) printf '3\n' ;;
    *) return 1 ;;
  esac
}

resolve_pts_tests() {
  [ "$RUN_PTS" -eq 1 ] || return 0
  [ -z "$PTS_TESTS" ] || return 0

  selected_rank="$(pts_tier_rank "$PTS_TIER")" || {
    printf 'Invalid PTS_TIER: %s (expected smoke, standard or extended)\n' "$PTS_TIER" >&2
    return 2
  }

  selected_tests=''
  for group in $PTS_GROUPS; do
    case "$group" in
      *[!a-zA-Z0-9_-]*)
        printf 'Invalid PTS group: %s\n' "$group" >&2
        return 2
        ;;
    esac
    catalog="$ROOT_DIR/config/pts/$group.list"
    if [ ! -r "$catalog" ]; then
      printf 'PTS catalog is missing: %s\n' "$catalog" >&2
      return 2
    fi
    while read -r test_profile test_tier remainder; do
      case "$test_profile" in ''|'#'*) continue ;; esac
      [ -z "$remainder" ] || {
        printf 'Invalid PTS catalog row: %s\n' "$test_profile $test_tier $remainder" >&2
        return 2
      }
      test_rank="$(pts_tier_rank "$test_tier")" || {
        printf 'Invalid PTS tier in %s: %s\n' "$catalog" "$test_tier" >&2
        return 2
      }
      [ "$test_rank" -le "$selected_rank" ] || continue
      case " $selected_tests " in
        *" $test_profile "*) ;;
        *) selected_tests="${selected_tests:+$selected_tests }$test_profile" ;;
      esac
    done < "$catalog"
  done
  PTS_TESTS="$selected_tests"
  export PTS_TESTS
  printf 'PTS selection: tier=%s groups=%s tests=%s\n' "$PTS_TIER" "$PTS_GROUPS" "$(printf '%s\n' "$PTS_TESTS" | wc -w | tr -d ' ')" | tee -a "$DETAIL"
}

report_pts_metrics() {
  metrics_file="$1"
  [ -s "$metrics_file" ] || return 1
  while IFS=$'\t' read -r metric_name metric_value metric_units; do
    [ -n "$metric_name" ] || continue
    printf 'LAVA_PTS_METRIC %s=%s %s\n' "$metric_name" "$metric_value" "$metric_units" | tee -a "$DETAIL"
    lava_result "$metric_name" --result pass --measurement "$metric_value" --units "$metric_units"
  done < "$metrics_file"
}
