stty -echo;
set -o pipefail;
: "${SELECTED_MODULES:?SELECTED_MODULES is required}";
: "${AUTO_INSTALL:=1}";
: "${AUTO_INSTALL_SOURCE:=1}";
: "${RUN_SPEC:=0}";
: "${RUN_PTS:=0}";
: "${RUN_LTP:=0}";
: "${RUN_STRESS:=0}";
: "${RUN_GPU:=1}";
: "${RUN_STORAGE:=1}";
: "${STRICT:=0}";
: "${STRESS_SECONDS:=300}";
: "${STORAGE_SIZE:=512M}";
: "${SPEC_AUTO_INIT:=1}";
: "${SPEC2017_ROOT:=}";
: "${SPEC2017_INSTALL_ROOT:=/home/leetfs/spec2017}";
: "${SPEC2017_MEDIA_URL:=https://smallquilt.quilt.idv.tw:8923/ouo/support/SPEC%20CPU%202017/CPU%202017%201.0.5.iso}";
: "${SPEC2017_SHA256_FILE:=config/cpu2017-1_0_5.iso.sha256}";
: "${SPEC2017_INSTALL_CMD:=}";
: "${SPEC2017_CONFIG:=auto}";
: "${SPEC2017_CMD:=runcpu --config=auto --size=ref intrate fprate}";
: "${PTS_TIER:=standard}";
: "${PTS_GROUPS:=cpu crypto compression memory storage toolchain runtime multimedia server kernel network}";
: "${PTS_TESTS=}";
: "${PTS_TIMES_TO_RUN:=1}";
: "${PTS_TEST_TIMEOUT:=4h}";
REPORT="$WORK_DIR/report.md";
DETAIL="$WORK_DIR/detail.log";
INSTALL_REPORT="$WORK_DIR/install.md";
SUITE_RESULTS="$WORK_DIR/suite-results.log";
PASS_COUNT=0;
FAIL_COUNT=0;
SKIP_COUNT=0;
TIMEOUT_COUNT=0;
: > "$DETAIL";
: > "$INSTALL_REPORT";
: > "$SUITE_RESULTS";
printf '# K1 LAVA 基准测试报告\n\n' > "$REPORT";
printf -- '- Started: %s\n- Host: %s\n- Kernel: %s\n\n' "$(date -Is)" "$(hostname)" "$(uname -a)" >> "$REPORT";
printf '## 依赖安装记录\n\n| 工具 | 状态 | 详情 |\n|---|---:|---|\n' >> "$INSTALL_REPORT";
suite_result() {
  case_id="$(printf '%s-%s' "$1" "$2" | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9.-')";
  case "$3" in
    PASS) lava_status=pass ;;
    SKIP) lava_status=skip ;;
    FAIL|TIMEOUT) lava_status=fail ;;
    *) lava_status=unknown ;;
  esac;
  printf 'LAVA_RESULT %s %s %s seconds rc=%s\n' "$case_id" "$3" "$4" "$5" >> "$SUITE_RESULTS";
  lava-test-case "$case_id" --result "$lava_status" --measurement "$4" --units seconds;
};
run_cmd() {
  category="$1";
  test_name="$2";
  limit="$3";
  probe="$4";
  command_text="$5";
  output_id="$(printf '%s-%s' "$category" "$test_name" | tr -cd 'a-zA-Z0-9._-')";
  output_file="$WORK_DIR/output-$output_id.log";
  : > "$output_file";
  started="$(date +%s)";
  printf '\n===== %s / %s =====\n' "$category" "$test_name" | tee -a "$DETAIL";
  if ! eval "$probe" >/dev/null 2>&1; then
    status=SKIP;
    rc=127;
    SKIP_COUNT=$((SKIP_COUNT + 1));
    printf 'SKIP: prerequisite unavailable\n' | tee -a "$DETAIL";
  else
    timeout --signal=TERM --kill-after=30s "$limit" bash -lc "$command_text" 2>&1 | tee -a "$DETAIL" "$output_file";
    rc=${PIPESTATUS[0]};
    if [ "$rc" -eq 0 ]; then
      status=PASS;
      PASS_COUNT=$((PASS_COUNT + 1));
    elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
      status=TIMEOUT;
      TIMEOUT_COUNT=$((TIMEOUT_COUNT + 1));
    else
      status=FAIL;
      FAIL_COUNT=$((FAIL_COUNT + 1));
    fi;
  fi;
  duration=$(( $(date +%s) - started ));
  printf '| %s | %s | %s | %s | %s |\n' "$category" "$test_name" "$status" "$rc" "$duration" >> "$REPORT";
  suite_result "$category" "$test_name" "$status" "$duration" "$rc";
  if [ "$status" = PASS ] && command -v collect_metrics >/dev/null 2>&1; then
    collect_metrics "$category" "$test_name" "$output_file";
  fi;
  printf 'RESULT: %s rc=%s duration=%ss\n' "$status" "$rc" "$duration" | tee -a "$DETAIL";
  return 0;
};
record_skip() {
  category="$1";
  test_name="$2";
  reason="$3";
  SKIP_COUNT=$((SKIP_COUNT + 1));
  printf '| %s | %s | SKIP | 127 | 0 |\n' "$category" "$test_name" >> "$REPORT";
  suite_result "$category" "$test_name" SKIP 0 127;
  printf '\n===== %s / %s =====\nSKIP: %s\n' "$category" "$test_name" "$reason" | tee -a "$DETAIL";
};
install_result() {
  printf '| %s | %s | %s |\n' "$1" "$2" "$3" >> "$INSTALL_REPORT";
  printf 'INSTALL: %s status=%s detail=%s\n' "$1" "$2" "$3" | tee -a "$DETAIL";
};
detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER=apt;
  elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER=dnf;
  else
    PACKAGE_MANAGER=none;
  fi;
};
update_package_index() {
  detect_package_manager;
  if [ "$AUTO_INSTALL" -ne 1 ]; then install_result package-index SKIP 'AUTO_INSTALL=0'; return 0; fi;
  case "$PACKAGE_MANAGER" in
    apt)
      if printf '%s\n' leetfs | sudo -S -p '' env DEBIAN_FRONTEND=noninteractive apt-get update 2>&1 | tee -a "$DETAIL"; then install_result package-index UPDATED apt; else install_result package-index FAILED 'apt-get update'; fi
      ;;
    dnf)
      if printf '%s\n' leetfs | sudo -S -p '' dnf -y makecache --refresh 2>&1 | tee -a "$DETAIL"; then install_result package-index UPDATED dnf; else install_result package-index FAILED 'dnf makecache'; fi
      ;;
    *) install_result package-index SKIP 'no supported package manager' ;;
  esac;
  return 0;
};
ensure_package() {
  label="$1";
  probe="$2";
  apt_packages="$3";
  dnf_packages="${4:-$3}";
  detect_package_manager;
  if eval "$probe" >/dev/null 2>&1; then install_result "$label" PRESENT "$PACKAGE_MANAGER"; return 0; fi;
  if [ "$AUTO_INSTALL" -ne 1 ] || [ "$PACKAGE_MANAGER" = none ]; then install_result "$label" UNAVAILABLE 'automatic package installation disabled or unavailable'; return 0; fi;
  case "$PACKAGE_MANAGER" in
    apt)
      packages="$apt_packages";
      if ! apt-cache show $packages >/dev/null 2>&1; then
        install_result "$label" NOT_FOUND "apt: $packages; trying source";
        return 0;
      fi;
      printf '%s\n' leetfs | sudo -S -p '' env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $packages 2>&1 | tee -a "$DETAIL";
      rc=${PIPESTATUS[1]}
      ;;
    dnf)
      packages="$dnf_packages";
      if ! dnf -q list --available $packages >/dev/null 2>&1; then
        install_result "$label" NOT_FOUND "dnf: $packages; trying source";
        return 0;
      fi;
      printf '%s\n' leetfs | sudo -S -p '' dnf install -y $packages 2>&1 | tee -a "$DETAIL";
      rc=${PIPESTATUS[1]}
      ;;
  esac;
  if [ "$rc" -eq 0 ] && eval "$probe" >/dev/null 2>&1; then
    install_result "$label" INSTALLED "$PACKAGE_MANAGER: $packages";
  elif [ "$rc" -eq 0 ]; then
    install_result "$label" UNAVAILABLE "$PACKAGE_MANAGER installed $packages but probe failed; trying source";
  else
    install_result "$label" UNAVAILABLE "$PACKAGE_MANAGER install $packages failed; trying source";
  fi;
  return 0;
};
ensure_source() {
  label="$1";
  probe="$2";
  command_text="$3";
  source_limit="${4:-2h}";
  if eval "$probe" >/dev/null 2>&1; then return 0; fi;
  if [ "$AUTO_INSTALL_SOURCE" -ne 1 ]; then install_result "$label-source" UNAVAILABLE 'source installation disabled'; return 0; fi;
  if timeout --signal=TERM --kill-after=30s "$source_limit" bash -lc "$command_text" 2>&1 | tee -a "$DETAIL"; then
    if eval "$probe" >/dev/null 2>&1; then install_result "$label-source" INSTALLED source; else install_result "$label-source" UNAVAILABLE 'build completed but probe failed'; fi;
  else
    install_result "$label-source" UNAVAILABLE 'source build failed';
  fi;
  return 0;
};
has_module() {
  case ",$SELECTED_MODULES," in
    *,"$1",*) return 0 ;;
  esac;
  return 1;
};
printf 'LAVA_BENCH_HARNESS_%s\n' READY
