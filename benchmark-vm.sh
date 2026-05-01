#!/bin/bash

# VM Benchmark Script
# Measures: response times, sequential load, concurrent load, and ApacheBench
# Usage: ./benchmark.sh http://192.168.1.138:5000/

set -e

API_URL=${1:-"http://192.168.1.138:5000/"}
RESULTS_DIR="./benchmark-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

echo "🚀 Starting VM Benchmark Suite"
echo "=================================="
echo "Target URL: $API_URL"

# 1. Check if server is reachable
echo ""
echo "📊 1. Checking VM Flask Server..."

START_TIME=$(date +%s%N)

until curl -s "$API_URL" > /dev/null 2>&1; do
    echo "Waiting for Flask server..."
    sleep 0.5
done

END_TIME=$(date +%s%N)
READY_MS=$(( (END_TIME - START_TIME) / 1000000 ))

echo "✅ Server reachable in ${READY_MS}ms"
echo "Server reachable time: ${READY_MS}ms" > "$RESULTS_DIR/startup_$TIMESTAMP.txt"

# 2. Single endpoint test
echo ""
echo "📊 2. Testing Flask Endpoint..."

time curl -s "$API_URL" > /dev/null

echo "✅ Endpoint tested"

# 3. Sequential load test
echo ""
echo "📊 3. Sequential Load Test (100 requests)..."

LOAD_FILE="$RESULTS_DIR/sequential_load_$TIMESTAMP.txt"
> "$LOAD_FILE"

START_TIME=$(date +%s%N)

for i in {1..100}; do
    curl -s "$API_URL" > /dev/null

    if [ $((i % 20)) -eq 0 ]; then
        echo "  Progress: $i/100 requests completed"
    fi
done

END_TIME=$(date +%s%N)
TOTAL_TIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))
AVG_TIME_MS=$(echo "scale=2; $TOTAL_TIME_MS / 100" | bc)

echo "✅ Sequential test completed in ${TOTAL_TIME_MS}ms"
echo "Total requests: 100" >> "$LOAD_FILE"
echo "Total time: ${TOTAL_TIME_MS}ms" >> "$LOAD_FILE"
echo "Average time/request: ${AVG_TIME_MS}ms" >> "$LOAD_FILE"

# 4. Concurrent load test
echo ""
echo "📊 4. Concurrent Load Test (50 parallel requests)..."

CONCURRENT_FILE="$RESULTS_DIR/concurrent_$TIMESTAMP.txt"
> "$CONCURRENT_FILE"

START_TIME=$(date +%s%N)

for i in {1..50}; do
    (curl -s "$API_URL" > /dev/null 2>&1) &
done

wait

END_TIME=$(date +%s%N)
TOTAL_TIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))
AVG_TIME_MS=$(echo "scale=2; $TOTAL_TIME_MS / 50" | bc)

echo "✅ 50 concurrent requests completed in ${TOTAL_TIME_MS}ms"
echo "Concurrent requests: 50" >> "$CONCURRENT_FILE"
echo "Total time: ${TOTAL_TIME_MS}ms" >> "$CONCURRENT_FILE"
echo "Average time/request: ${AVG_TIME_MS}ms" >> "$CONCURRENT_FILE"

# 5. ApacheBench test
echo ""
echo "📊 5. ApacheBench Test (1000 requests, 50 concurrent)..."

if ! command -v ab &> /dev/null; then
    echo "❌ ApacheBench not installed."
    echo "Install on macOS: brew install httpd"
    exit 1
fi

AB_FILE="$RESULTS_DIR/ab_test_$TIMESTAMP.txt"

ab -n 1000 -c 50 "$API_URL" > "$AB_FILE" 2>&1

echo "✅ ApacheBench results saved to $AB_FILE"
tail -20 "$AB_FILE"

echo ""
echo "=================================="
echo "✅ VM Benchmark Complete!"
echo "📁 Results saved to: $RESULTS_DIR/"
ls -lh "$RESULTS_DIR"/*_$TIMESTAMP.*
