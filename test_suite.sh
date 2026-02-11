#!/bin/bash
set -e

logDir="logFiles"
mkdir -p "$logDir"

# -------------------
# Network latency
# -------------------
echo -e "running network latency test\n"
ping 1.1.1.1 -c 20 > "$logDir/netPingTest.txt" 2>&1 || true
echo -e "\ntest done"
echo ""

# -------------------
# Network / HTTP burst
# -------------------
echo -e "running http burst test\n"

targets=("https://www.google.com" "https://www.cloudflare.com")
concurrency=10

echo "HTTP Burst Results" > "$logDir/httpBurst.txt"

for target in "${targets[@]}"
do
  ok=0; fail=0
  start=$(date +%s)

  pids=()
  for i in $(seq 1 "$concurrency")
  do
    curl -fsS -o /dev/null "$target" >/dev/null 2>&1 &
    pids+=("$!")
  done

  for pid in "${pids[@]}"
  do
    if wait "$pid"; then ok=$((ok+1)); else fail=$((fail+1)); fi
  done

  end=$(date +%s)

  {
    echo "Target: $target"
    echo "Success: $ok"
    echo "Fail: $fail"
    echo "Elapsed: $((end-start)) seconds"
    echo ""
  } >> "$logDir/httpBurst.txt"
done

echo -e "\ntest done"
echo ""

# -------------------
# Disk test - randwrite
# -------------------
echo -e "disk test - randwrite\n"
fio --name=testRandwrite \
  --output="$logDir/testRandwrite" \
  --filename="$HOME/fio_randwrite.bin" \
  --size=1200M \
  --rw=randwrite \
  --direct=1 \
  --bs=4k \
  --iodepth=16 \
  --runtime=20 \
  --time_based \
  --unlink=1 \
  --group_reporting \
  > /dev/null 2>&1
echo -e "\ntest done"
echo ""

# -------------------
# Disk test - read
# -------------------
echo -e "disk test - read\n"
fio --name=testRead \
  --output="$logDir/testRead" \
  --filename="$HOME/fio_read.bin" \
  --size=1200M \
  --rw=read \
  --direct=1 \
  --bs=1M \
  --iodepth=16 \
  --runtime=20 \
  --time_based \
  --unlink=1 \
  --group_reporting \
  > /dev/null 2>&1
echo -e "\ntest done"
echo ""

# -------------------
# CPU speed
# -------------------
echo -e "cpu test\n"
sysbench cpu --cpu-max-prime=500 --threads="$(nproc)" run > "$logDir/testCPU" 2>&1
echo -e "\ntest done"
echo ""

# -------------------
# iperf
# -------------------
if [ -n "${IPERF_SERVER:-}" ]; then
  echo -e "iperf test\n"
  iperf3 -c "$IPERF_SERVER" -p 5201 -t 30 -P 4 > "$logDir/testIperf" 2>&1 || true
  echo -e "\ntest done"
  echo ""
else
  echo -e "iperf skipped (set IPERF_SERVER)\n"
fi

echo "all tests done"
echo "logs in: $logDir"
