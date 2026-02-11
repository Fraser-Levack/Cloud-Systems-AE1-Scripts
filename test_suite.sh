#!/bin/bash
set -e

logDir="logFiles"
mkdir -p "$logDir"

for iteration in 1 2 3
do
	echo "===== RUN $iteration ====="

  # -------------------
  # Network latency
  # -------------------
  echo -e "running network latency test\n"
  ping 1.1.1.1 -c 20 > "$logDir/netPingTest_$iteration.txt" 2>&1 || true
  echo -e "\ntest done"
  echo ""

  # -------------------
  # Network / HTTP burst
  # -------------------
  echo -e "running http burst test\n"

  targets=("https://www.google.com" "https://www.cloudflare.com")
  concurrency=10

  echo "HTTP Burst Results" > "$logDir/httpBurst_$iteration.txt"

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
    } >> "$logDir/httpBurst_$iteration.txt"
  done

  echo -e "\ntest done"
  echo ""

  # -------------------
  # Disk test - randwrite
  # -------------------
  echo -e "disk test - randwrite\n"
  fio --name=testRandwrite \
    --output="$logDir/testRandwrite_$iteration" \
    --filename="$HOME/fio_randwrite.bin" \
    --size=1200M \
    --rw=randwrite \
    --direct=1 \
    --bs=4k \
    --iodepth=16 \
    --runtime=60 \
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
    --output="$logDir/testRead_$iteration" \
    --filename="$HOME/fio_read.bin" \
    --size=1200M \
    --rw=read \
    --direct=1 \
    --bs=1M \
    --iodepth=16 \
    --runtime=60 \
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
  sysbench cpu --time=60 --threads="$(nproc)" run > "$logDir/testCPU_$iteration" 2>&1
  echo -e "\ntest done"
  echo ""

  # -------------------
  # iperf
  # -------------------
  if [ -n "${IPERF_SERVER:-}" ]; then
    echo -e "iperf test\n"
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 60 -P 1 > "$logDir/testIperf_$iteration" 2>&1 || true
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 60 -P 2 > "$logDir/testIperf_scale2_$iteration" 2>&1 || true
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 60 -P 4 > "$logDir/testIperf_scale4_$iteration" 2>&1 || true
    echo -e "\ntest done"
    echo ""
  else
    echo -e "iperf skipped (set IPERF_SERVER)\n"
  fi

done

echo "======LONG=TERM=TESTS======"

# -------------------
  # Disk test - randwrite
  # -------------------
  echo -e "disk test - randwrite\n"
  fio --name=testRandwrite \
    --output="$logDir/testRandwrite_LongTerm" \
    --filename="$HOME/fio_randwrite.bin" \
    --size=1200M \
    --rw=randwrite \
    --direct=1 \
    --bs=4k \
    --iodepth=16 \
    --runtime=600 \
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
    --output="$logDir/testRead_LongTerm" \
    --filename="$HOME/fio_read.bin" \
    --size=1200M \
    --rw=read \
    --direct=1 \
    --bs=1M \
    --iodepth=16 \
    --runtime=600 \
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
  sysbench cpu --time=600 --threads="$(nproc)" run > "$logDir/testCPU_LongTerm" 2>&1
  echo -e "\ntest done"
  echo ""

  # -------------------
  # iperf
  # -------------------
  if [ -n "${IPERF_SERVER:-}" ]; then
    echo -e "iperf test\n"
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 600 -P 1 > "$logDir/testIperf_LongTerm" 2>&1 || true
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 600 -P 2 > "$logDir/testIperf_scale2_LongTerm" 2>&1 || true
    iperf3 -c "$IPERF_SERVER" -p 5201 -t 600 -P 4 > "$logDir/testIperf_scale4_LongTerm" 2>&1 || true
    echo -e "\ntest done"
    echo ""
  else
    echo -e "iperf skipped (set IPERF_SERVER)\n"
  fi


echo "all tests done"
echo "logs in: $logDir"

