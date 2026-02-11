#!/bin/bash
set -e

logDir="${LOG_DIR:-logFiles}"
mkdir -p "$logDir"

PING_TARGET="${PING_TARGET:-1.1.1.1}"
PING_COUNT="${PING_COUNT:-20}"

HTTP_TARGETS=${HTTP_TARGETS:-"https://www.google.com https://www.cloudflare.com"}
HTTP_CONCURRENCY="${HTTP_CONCURRENCY:-10}"

DISK_SIZE="${DISK_SIZE:-1200M}"
DISK_IODEPTH="${DISK_IODEPTH:-16}"
DISK_DIRECT="${DISK_DIRECT:-1}"
DISK_TARGET_DIR="${DISK_TARGET_DIR:-$HOME}"

CPU_MAX_PRIME="${CPU_MAX_PRIME:-500}"
CPU_THREADS="${CPU_THREADS:-$(nproc)}"

IPERF_SERVER="${IPERF_SERVER:-}"
IPERF_PORT="${IPERF_PORT:-5201}"
IPERF_DURATION="${IPERF_DURATION:-30}"
IPERF_CLIENTS_LIST="${IPERF_CLIENTS_LIST:-1 2 4 8}"
IPERF_REVERSE="${IPERF_REVERSE:-1}"

summary="$logDir/summary.txt"
echo "Benchmark Summary - $(date -Is)" > "$summary"
echo >> "$summary"

# -------------------
# Ping
# -------------------
echo "### Network Latency (ping)" >> "$summary"
ping -c "$PING_COUNT" "$PING_TARGET" 2>/dev/null \
  | grep -E 'packets transmitted|rtt min/avg/max' \
  >> "$summary" || echo "Ping failed" >> "$summary"
echo >> "$summary"

# -------------------
# HTTP Burst
# -------------------
echo "### HTTP Burst Test" >> "$summary"
for target in $HTTP_TARGETS
do
  ok=0; fail=0
  pids=""

  for j in $(seq 1 "$HTTP_CONCURRENCY")
  do
    curl -fsS -o /dev/null "$target" >/dev/null 2>&1 &
    pids="$pids $!"
  done

  for pid in $pids
  do
    if wait "$pid"; then ok=$((ok+1)); else fail=$((fail+1)); fi
  done

  echo "$target → ok=$ok fail=$fail" >> "$summary"
done
echo >> "$summary"

# -------------------
# Disk - Random Write
# -------------------
echo "### Disk Random Write" >> "$summary"
fio --name=randwrite \
  --filename="$DISK_TARGET_DIR/fio.bin" \
  --size="$DISK_SIZE" \
  --rw=randwrite \
  --bs=4k \
  --iodepth="$DISK_IODEPTH" \
  --direct="$DISK_DIRECT" \
  --runtime=20 \
  --time_based \
  --unlink=1 \
  --group_reporting \
  2>/dev/null \
  | grep -E 'WRITE:|IOPS=|BW=' \
  >> "$summary" || echo "Disk test failed" >> "$summary"
echo >> "$summary"

# -------------------
# CPU
# -------------------
echo "### CPU Test" >> "$summary"
sysbench cpu \
  --cpu-max-prime="$CPU_MAX_PRIME" \
  --threads="$CPU_THREADS" run 2>/dev/null \
  | grep -E 'events per second:|avg:|max:' \
  >> "$summary" || echo "CPU test failed" >> "$summary"
echo >> "$summary"

# -------------------
# iPerf
# -------------------
if [ -n "$IPERF_SERVER" ]; then
  echo "### iPerf Test" >> "$summary"
  for n in $IPERF_CLIENTS_LIST
  do
    if [ "$IPERF_REVERSE" = "1" ]; then
      iperf3 -c "$IPERF_SERVER" -p "$IPERF_PORT" \
        -t "$IPERF_DURATION" -P "$n" -R 2>/dev/null \
        | grep receiver >> "$summary"
    else
      iperf3 -c "$IPERF_SERVER" -p "$IPERF_PORT" \
        -t "$IPERF_DURATION" -P "$n" 2>/dev/null \
        | grep receiver >> "$summary"
    fi
  done
  echo >> "$summary"
fi

echo "All tests complete."
echo "Summary saved to: $summary"
