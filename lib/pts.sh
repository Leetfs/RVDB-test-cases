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

report_pts_json() {
  json_file="$1"
  profile_name="$2"
  [ -s "$json_file" ] || return 0

  python3 - "$json_file" "$profile_name" <<'PY' | while IFS=$'\t' read -r metric_name metric_value metric_units; do
import json
import re
import sys

path, profile = sys.argv[1:]
with open(path, encoding="utf-8") as stream:
    document = json.load(stream)

used = set()
for result in document.get("results", {}).values():
    description = result.get("description") or result.get("title") or "result"
    slug = re.sub(r"[^a-z0-9]+", "-", description.lower()).strip("-")[:48] or "result"
    for value_entry in result.get("results", {}).values():
        value = value_entry.get("value")
        if not isinstance(value, (int, float)):
            continue
        base = f"pts-{profile}-{slug}"[:90].rstrip("-")
        name = base
        suffix = 2
        while name in used:
            tail = f"-{suffix}"
            name = base[: 90 - len(tail)].rstrip("-") + tail
            suffix += 1
        used.add(name)
        units = re.sub(r"[^a-zA-Z0-9%./_-]+", "-", result.get("scale") or "score").strip("-") or "score"
        print(name, value, units, sep="\t")
PY
    [ -n "$metric_name" ] || continue
    printf 'LAVA_PTS_METRIC %s=%s %s\n' "$metric_name" "$metric_value" "$metric_units" | tee -a "$DETAIL"
    lava-test-case "$metric_name" --result pass --measurement "$metric_value" --units "$metric_units"
  done
}
