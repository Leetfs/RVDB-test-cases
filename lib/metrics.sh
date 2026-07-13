METRIC_REPORT="$WORK_DIR/metrics.md"
printf '## 结构化性能指标\n\n| 测试项 | 指标 | 数值 | 单位 |\n|---|---|---:|---|\n' > "$METRIC_REPORT"

metric_slug() {
  printf '%s' "$1" | tr '[:upper:]_ /' '[:lower:]----' | tr -cd 'a-z0-9.-' | cut -c1-100
}

emit_metric() {
  category="$1"
  test_name="$2"
  metric_name="$3"
  value="$(printf '%s' "$4" | tr -d ',')"
  units="$5"
  printf '%s\n' "$value" | grep -Eq '^-?[0-9]+([.][0-9]+)?$' || return 0
  metric_id="$(metric_slug "$category-$test_name-$metric_name")"
  [ -n "$metric_id" ] || return 0
  printf '| %s-%s | %s | %s | %s |\n' "$category" "$test_name" "$metric_name" "$value" "$units" >> "$METRIC_REPORT"
  printf 'LAVA_METRIC %s value=%s units=%s\n' "$metric_id" "$value" "$units" | tee -a "$DETAIL" "$SUITE_RESULTS"
  lava_result "$metric_id" --result pass --measurement "$value" --units "$units"
}

emit_metric_lines() {
  category="$1"
  test_name="$2"
  while IFS='|' read -r metric_name value units; do
    [ -n "$metric_name" ] || continue
    emit_metric "$category" "$test_name" "$metric_name" "$value" "$units"
  done
}

parse_coremark() {
  awk '/CoreMark 1[.]0/ { line=$0; sub(/^.*:[[:space:]]*/, "", line); split(line, f, /[[:space:]]+/); if (f[1] ~ /^[0-9]+([.][0-9]+)?$/) print "score|" f[1] "|iterations-per-second"; exit }' "$1"
}

parse_coremark_pro() {
  awk '$1 == "CoreMark-PRO" && $2 ~ /^[0-9]+([.][0-9]+)?$/ { print "multicore-score|" $2 "|score"; if ($3 ~ /^[0-9]+([.][0-9]+)?$/) print "singlecore-score|" $3 "|score"; if ($4 ~ /^[0-9]+([.][0-9]+)?$/) print "scaling|" $4 "|ratio"; exit }' "$1"
}

parse_unixbench() {
  awk '/System Benchmarks Index Score/ && $NF ~ /^[0-9]+([.][0-9]+)?$/ { print "index-score|" $NF "|score" }' "$1" | tail -1
}

parse_openssl() {
  awk '
    function scaled(v, x) { x=v; if (x ~ /k$/) {sub(/k$/, "", x); return x} if (x ~ /M$/) {sub(/M$/, "", x); return x*1000} if (x ~ /G$/) {sub(/G$/, "", x); return x*1000000} return x/1000 }
    BEGIN { split("16 64 256 1024 8192 16384", blocks, " ") }
    /^(aes-|sm3|sm4|ChaCha20|chacha20)/ {
      alg=$1; for (i=2; i<=NF && i<=7; i++) if ($i ~ /^[0-9]+([.][0-9]+)?[kMG]?$/) print alg "-" blocks[i-1] "b|" scaled($i) "|kB-per-second"
    }
    /sign\/s.*verify\/s/ { sm2=1; next }
    sm2 && $(NF-1) ~ /^[0-9]+([.][0-9]+)?$/ && $NF ~ /^[0-9]+([.][0-9]+)?$/ { print "sign|" $(NF-1) "|operations-per-second"; print "verify|" $NF "|operations-per-second"; sm2=0 }
  ' "$1"
}

parse_7zip() {
  awk '/^Tot:/ { for (i=NF; i>=1; i--) if ($i ~ /^[0-9]+$/) { print "total|" $i "|MIPS"; exit } }' "$1"
}

parse_stockfish() {
  awk -F: '/Nodes\/second/ { gsub(/[ ,]/, "", $2); if ($2 ~ /^[0-9]+$/) print "nodes-per-second|" $2 "|nodes-per-second" }' "$1" | tail -1
}

parse_stream() {
  awk '/^(Copy|Scale|Add|Triad):/ && $2 ~ /^[0-9]+([.][0-9]+)?$/ { name=tolower($1); sub(/:$/, "", name); print name "|" $2 "|MB-per-second" }' "$1"
}

parse_score() {
  awk '/[Ss]core:/ { for (i=NF; i>=1; i--) if ($i ~ /^[0-9]+([.][0-9]+)?$/) { print "score|" $i "|score"; exit } }' "$1"
}

parse_vkpeak() {
  awk -F= '/^[[:space:]]*[A-Za-z0-9-]+[[:space:]]*=/ { name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); n=split($2, f, /[[:space:]]+/); value=""; unit=""; for (i=1; i<=n; i++) if (f[i] ~ /^[0-9]+([.][0-9]+)?$/) {value=f[i]; unit=f[i+1]; break} if (value != "") print name "|" value "|" unit }' "$1"
}

parse_clpeak() {
  awk '
    /^[A-Za-z].*$/ && $0 !~ /:/ { section=$0; gsub(/^[[:space:]]+|[[:space:]]+$/, "", section); gsub(/[[:space:]]+/, "-", section); next }
    /:[[:space:]]*[0-9]+([.][0-9]+)?[[:space:]]+[A-Za-z]+/ { name=$0; sub(/:.*/, "", name); gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); gsub(/[[:space:]]+/, "-", name); if (match($0, /[0-9]+([.][0-9]+)?/)) { value=substr($0,RSTART,RLENGTH); rest=substr($0,RSTART+RLENGTH); gsub(/^[[:space:]]+/, "", rest); split(rest,u,/[[:space:]]+/); print section "-" name "|" value "|" u[1] } }
  ' "$1" | head -40
}

parse_tinymembench() {
  awk -F: '/MB\/s|nanoseconds| ns/ { name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); gsub(/[[:space:]]+/, "-", name); if (match($2, /[0-9]+([.][0-9]+)?/)) {value=substr($2, RSTART, RLENGTH); unit=($0 ~ /MB\/s/) ? "MB-per-second" : "nanoseconds"; print name "|" value "|" unit} }' "$1" | head -40
}

parse_lmbench() {
  awk -F: '/microseconds|nanoseconds/ { name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); gsub(/[[:space:]]+/, "-", name); if (match($2, /[0-9]+([.][0-9]+)?/)) {value=substr($2, RSTART, RLENGTH); unit=($0 ~ /microseconds/) ? "microseconds" : "nanoseconds"; print name "|" value "|" unit} }' "$1" | head -20
}

parse_mhz() {
  awk '/MHz/ { for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+([.][0-9]+)?$/) { print "measured-frequency|" $i "|MHz"; exit } }' "$1"
}

parse_cpufreq() {
  awk '/policy[0-9]+/ { policy=$1; sub(/^.*policy/, "policy", policy); count=0; for (i=2; i<=NF; i++) if ($i ~ /^[0-9]+$/) { count++; if (count==1) print policy "-current|" $i/1000 "|MHz"; if (count==2) print policy "-minimum|" $i/1000 "|MHz"; if (count==3) print policy "-maximum|" $i/1000 "|MHz" } }' "$1"
}

parse_generic_units() {
  awk -F: '/nanoseconds|microseconds| ns| MB\/s| GB\/s/ { name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); gsub(/[[:space:]]+/, "-", name); if (match($2, /[0-9]+([.][0-9]+)?/)) { value=substr($2,RSTART,RLENGTH); unit="value"; if ($0 ~ /nanoseconds| ns/) unit="nanoseconds"; else if ($0 ~ /microseconds/) unit="microseconds"; else if ($0 ~ /MB\/s/) unit="MB-per-second"; else if ($0 ~ /GB\/s/) unit="GB-per-second"; print name "|" value "|" unit } }' "$1" | head -40
}

parse_fio() {
  awk '
    function scale(v, x) { x=v; if (x ~ /k$/) {sub(/k$/, "", x); return x*1000} if (x ~ /M$/) {sub(/M$/, "", x); return x*1000000} return x }
    /^[[:space:]]*(READ|WRITE):/ { mode=tolower($1); sub(/:$/, "", mode); if (match($0, /IOPS=[0-9.]+[kM]?/)) {v=substr($0,RSTART+5,RLENGTH-5); print mode "-iops|" scale(v) "|IOPS"} if (match($0, /bw=[0-9.]+[KMGT]i?B\/s/)) {v=substr($0,RSTART+3,RLENGTH-3); if (match(v,/^[0-9.]+/)) {n=substr(v,RSTART,RLENGTH); u=substr(v,RLENGTH+1); print mode "-bandwidth|" n "|" u}} }
  ' "$1"
}

parse_iozone() {
  awk '
    $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && NF >= 8 { line=$0 }
    END { if (line != "") { gsub(/^[[:space:]]+/, "", line); n=split(line,f,/[[:space:]]+/); names[3]="write"; names[4]="rewrite"; names[5]="read"; names[6]="reread"; names[7]="random-read"; names[8]="random-write"; for (i=3; i<=8 && i<=n; i++) if (f[i] ~ /^[0-9]+([.][0-9]+)?$/) print names[i] "|" f[i] "|kB-per-second" } }
  ' "$1"
}

parse_thermal() {
  awk 'match($0, /temp=[0-9]+/) { value=substr($0, RSTART+5, RLENGTH-5); name="zone" count; if (match($0, /thermal_zone[0-9]+/)) name=substr($0,RSTART,RLENGTH); print name "|" value/1000 "|celsius"; count++ }' "$1"
}

parse_stress_ng() {
  awk '/stress-ng: (metrc|metrics):/ { line=$0; sub(/^.*\] /, "", line); n=split(line,f,/[[:space:]]+/); if (n >= 2 && f[1] ~ /^[A-Za-z0-9_-]+$/ && f[2] ~ /^[0-9]+$/) { print f[1] "-bogo-ops|" f[2] "|operations"; if (f[7] ~ /^[0-9]+([.][0-9]+)?$/) print f[1] "-bogo-ops-per-second|" f[7] "|operations-per-second" } }' "$1" | head -40
}

parse_spec2017() {
  awk '/SPEC(rate|speed)2017_(int|fp)_(base|peak)/ { for (i=NF; i>=1; i--) if ($i ~ /^[0-9]+([.][0-9]+)?$/) { name=$1; print name "|" $i "|ratio"; break } }' "$1" | tail -20
}

parse_iperf3() {
  awk '/receiver/ && /bits\/sec/ { for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+([.][0-9]+)?$/ && $(i+1) ~ /bits\/sec/) { print "receive-bandwidth|" $i "|" $(i+1); line=1 } } END { if (!line) exit 0 }' "$1" | tail -1
}

parse_sockperf() {
  awk 'tolower($0) ~ /latency.*[0-9].*(usec|msec|nsec)/ { if (match($0, /[0-9]+([.][0-9]+)?/)) { value=substr($0,RSTART,RLENGTH); unit="microseconds"; if (tolower($0) ~ /msec/) unit="milliseconds"; else if (tolower($0) ~ /nsec/) unit="nanoseconds"; print "latency|" value "|" unit } }' "$1" | tail -1
}

parse_qperf() {
  awk -F= '/(bw|latency)[[:space:]]*=/ { name=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", name); value=$2; gsub(/^[[:space:]]+/, "", value); split(value,f,/[[:space:]]+/); if (f[1] ~ /^[0-9]+([.][0-9]+)?$/) print name "|" f[1] "|" f[2] }' "$1"
}

parse_cyclictest() {
  awk '/Max:/ { for (i=1; i<=NF; i++) if ($i == "Max:" && $(i+1) ~ /^[0-9]+$/) { if ($(i+1) > max) max=$(i+1) } } END { if (max != "") print "maximum-latency|" max "|microseconds" }' "$1"
}

parse_hackbench() {
  awk -F: '/Total time/ { value=$2; gsub(/[^0-9.]/, "", value); if (value ~ /^[0-9]+([.][0-9]+)?$/) print "total-time|" value "|seconds" }' "$1" | tail -1
}

collect_metrics() {
  category="$1"
  test_name="$2"
  output_file="$3"
  [ -s "$output_file" ] || return 0
  case "$category-$test_name" in
    cpu-coremark) parse_coremark "$output_file" ;;
    cpu-coremark-pro) parse_coremark_pro "$output_file" ;;
    cpu-unixbench|combined-byte-unixbench) parse_unixbench "$output_file" ;;
    cpu-openssl-*) parse_openssl "$output_file" ;;
    cpu-7zip) parse_7zip "$output_file" ;;
    cpu-stockfish) parse_stockfish "$output_file" ;;
    cpu-spec-cpu2017) parse_spec2017 "$output_file" ;;
    info-cpufreq) parse_cpufreq "$output_file" ;;
    info-mhz) parse_mhz "$output_file" ;;
    ram-tinymembench) parse_tinymembench "$output_file" ;;
    ram-ramlat|ram-core-to-core-latency) parse_generic_units "$output_file" ;;
    ram-stream) parse_stream "$output_file" ;;
    gpu-glmark2|gpu-vkmark|gpu-gfxbench) parse_score "$output_file" ;;
    gpu-vkpeak) parse_vkpeak "$output_file" ;;
    gpu-clpeak) parse_clpeak "$output_file" ;;
    combined-lmbench-*) parse_lmbench "$output_file" ;;
    storage-fio) parse_fio "$output_file" ;;
    storage-iozone) parse_iozone "$output_file" ;;
    stability-thermal-*) parse_thermal "$output_file" ;;
    stability-stress-ng) parse_stress_ng "$output_file" ;;
    network-iperf3-loopback) parse_iperf3 "$output_file" ;;
    network-sockperf-loopback) parse_sockperf "$output_file" ;;
    network-qperf-loopback) parse_qperf "$output_file" ;;
    realtime-cyclictest) parse_cyclictest "$output_file" ;;
    realtime-hackbench) parse_hackbench "$output_file" ;;
    *) return 0 ;;
  esac | emit_metric_lines "$category" "$test_name"
}
