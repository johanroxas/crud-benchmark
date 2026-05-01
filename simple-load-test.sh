#!/bin/bash

# Simple Load Test - Quick 100 request test with response stability check

API_URL="${1:-http://localhost:3000}"
NUM_REQUESTS="${2:-100}"

echo "🚀 Simple Load Test"
echo "URL: $API_URL"
echo "Requests: $NUM_REQUESTS"
echo ""

# Check if server is running
if ! curl -s "$API_URL/tasks" > /dev/null 2>&1; then
    echo "❌ Server not responding at $API_URL"
    exit 1
fi

echo "Starting load test..."
echo ""

RESPONSE_TIMES=()
FAILED=0
SUCCESS=0

START_TIME=$(date +%s%N)

for i in $(seq 1 $NUM_REQUESTS); do
    REQ_START=$(date +%s%N)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/tasks")
    REQ_END=$(date +%s%N)

    RESPONSE_TIME=$(( (REQ_END - REQ_START) / 1000000 ))
    RESPONSE_TIMES+=($RESPONSE_TIME)

    if [ "$HTTP_CODE" = "200" ]; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        echo "⚠️  Request $i returned HTTP $HTTP_CODE"
    fi

    if [ $((i % 20)) -eq 0 ]; then
        echo "Progress: $i/$NUM_REQUESTS"
    fi
done

END_TIME=$(date +%s%N)
TOTAL_TIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))

# Calculate statistics
MIN_TIME=${RESPONSE_TIMES[0]}
MAX_TIME=${RESPONSE_TIMES[0]}
SUM=0

for time in "${RESPONSE_TIMES[@]}"; do
    SUM=$((SUM + time))
    if [ $time -lt $MIN_TIME ]; then
        MIN_TIME=$time
    fi
    if [ $time -gt $MAX_TIME ]; then
        MAX_TIME=$time
    fi
done

AVG_TIME=$(echo "scale=2; $SUM / $NUM_REQUESTS" | bc)

echo ""
echo "=================================="
echo "📊 RESULTS"
echo "=================================="
echo "Total Requests: $NUM_REQUESTS"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo "Success Rate: $(echo "scale=1; $SUCCESS * 100 / $NUM_REQUESTS" | bc)%"
echo ""
echo "Response Times (ms):"
echo "  Min:     ${MIN_TIME}ms"
echo "  Max:     ${MAX_TIME}ms"
echo "  Avg:     ${AVG_TIME}ms"
echo "  Total:   ${TOTAL_TIME_MS}ms"
echo ""
echo "Requests/sec: $(echo "scale=2; $NUM_REQUESTS * 1000 / $TOTAL_TIME_MS" | bc)"
echo "=================================="
