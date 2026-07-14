#!/usr/bin/env bash
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR
PROFILE="${1:-full}"
PROFILE_FILE="$ROOT_DIR/profiles/$PROFILE.env"
RVDB_REQUESTED_MODULES="${RVDB_SELECTED_MODULES:-}"

if [[ ! -r "$PROFILE_FILE" ]]; then
  printf 'Unknown profile: %s\n' "$PROFILE" >&2
  exit 2
fi

# shellcheck source=/dev/null
source "$ROOT_DIR/config/defaults.env"
# shellcheck source=/dev/null
source "$PROFILE_FILE"

# Web 平台通过 LAVA test definition parameters 传入模块列表。默认仍使用 profile，
# 因此现有手工提交模板的行为不变。
if [[ -n "$RVDB_REQUESTED_MODULES" ]]; then
  PROFILE_MODULES="$RVDB_REQUESTED_MODULES"
fi

: "${PROFILE_MODULES:?PROFILE_MODULES is required in $PROFILE_FILE}"
SELECTED_MODULES="$(tr ' ' ',' <<<"$PROFILE_MODULES")"

# shellcheck source=/dev/null
source "$ROOT_DIR/lib/cleanup.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/harness.sh"
source "$ROOT_DIR/lib/metrics.sh"
source "$ROOT_DIR/lib/tap.sh"
source "$ROOT_DIR/lib/spec.sh"
source "$ROOT_DIR/lib/pts.sh"
resolve_pts_tests || exit $?
source "$ROOT_DIR/modules/install.sh"
initialize_spec

for module in $PROFILE_MODULES; do
  module_file="$ROOT_DIR/modules/$module.sh"
  if [[ ! -r "$module_file" ]]; then
    printf 'Missing module: %s\n' "$module_file" >&2
    exit 3
  fi
  # shellcheck source=/dev/null
  source "$module_file"
done

source "$ROOT_DIR/modules/report.sh"
source "$ROOT_DIR/modules/exit.sh"
