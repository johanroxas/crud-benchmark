#!/bin/bash

# CRUD Benchmark Script
# Measures: startup time, resource usage, response times, and load testing

set -e

API_URL="http://localhost:3000"
RESULTS_DIR="./benchmark-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

echo "🚀 Starting CRUD Benchmark Suite"
echo "=================================="

# Function to measure startup time
measure_startup() {
    echo ""
    echo "📊 1. Measuring Startup Time..."

    # Kill any existing container
    docker-compose down 2>/dev/null || true
    sleep 2

    # Start and measure
    START_TIME=$(date +%s%N)
    docker-compose up -d

    # Wait for server to be ready
    max_attempts=30
    attempt=0
    until curl -s "$API_URL/tasks" > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "❌ Server failed to start"
            docker-compose logs
            exit 1
        fi
        sleep 0.5
    done

    END_TIME=$(date +%s%N)
    STARTUP_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    echo "✅ Startup time: ${STARTUP_MS}ms"
    echo "Startup time: ${STARTUP_MS}ms" >> "$RESULTS_DIR/startup_$TIMESTAMP.txt"
}

# Function to measure resource usage
measure_resources() {
    echo ""
    echo "📊 2. Measuring Resource Usage (10 seconds)..."

    CONTAINER_ID=$(docker-compose ps -q app)

    echo "Timestamp,CPU%,Memory(MB)" > "$RESULTS_DIR/resources_$TIMESTAMP.csv"

    for i in {1..10}; do
        STATS=$(docker stats --no-stream "$CONTAINER_ID" 2>/dev/null | tail -1)
        CPU=$(echo "$STATS" | awk '{print $3}' | sed 's/%//')
        MEM=$(echo "$STATS" | awk '{print $4}' | sed 's/MiB//')

        echo "$(date +%T),$CPU,$MEM" >> "$RESULTS_DIR/resources_$TIMESTAMP.csv"
        sleep 1
    done

    echo "✅ Resource data saved to resources_$TIMESTAMP.csv"
}

# Function to test single requests
test_endpoints() {
    echo ""
    echo "📊 3. Testing Endpoints..."

    echo "" > "$RESULTS_DIR/response_times_$TIMESTAMP.txt"

    # GET all tasks
    echo "Testing GET /tasks..."
    time curl -s "$API_URL/tasks" > /dev/null

    # POST new task
    echo "Testing POST /tasks..."
    TASK_ID=$(curl -s -X POST "$API_URL/tasks" \
        -H "Content-Type: application/json" \
        -d '{"title":"Test Task"}' | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    echo "Created task ID: $TASK_ID"

    # PUT update task
    if [ ! -z "$TASK_ID" ]; then
        echo "Testing PUT /tasks/$TASK_ID..."
        curl -s -X PUT "$API_URL/tasks/$TASK_ID" > /dev/null
    fi

    echo "✅ Endpoints tested"
}

# Function for load testing with curl loop
load_test_curl() {
    echo ""
    echo "📊 4. Load Testing with curl (100 requests)..."

    RESULTS_FILE="$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    > "$RESULTS_FILE"

    START_TIME=$(date +%s%N)

    for i in {1..100}; do
        RESPONSE_TIME=$( { time curl -s -X GET "$API_URL/tasks" > /dev/null; } 2>&1 | grep real | awk '{print $2}')
        echo "$i,$RESPONSE_TIME" >> "$RESULTS_FILE"

        if [ $((i % 20)) -eq 0 ]; then
            echo "  Progress: $i/100 requests completed"
        fi
    done

    END_TIME=$(date +%s%N)
    TOTAL_TIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    echo "✅ Load test completed in ${TOTAL_TIME_MS}ms"

    # Calculate stats
    TOTAL_REQUESTS=100
    AVG_TIME_MS=$(echo "scale=2; $TOTAL_TIME_MS / $TOTAL_REQUESTS" | bc)
    echo "Average response time: ${AVG_TIME_MS}ms"
    echo "" >> "$RESULTS_FILE"
    echo "Total requests: $TOTAL_REQUESTS" >> "$RESULTS_FILE"
    echo "Total time: ${TOTAL_TIME_MS}ms" >> "$RESULTS_FILE"
    echo "Average time: ${AVG_TIME_MS}ms" >> "$RESULTS_FILE"
}

# Function for Apache Benchmark (if available)
load_test_ab() {
    if ! command -v ab &> /dev/null; then
        echo ""
        echo "⚠️  Apache Benchmark (ab) not installed. Skipping Apache Benchmark test."
        echo "   Install with: brew install httpd"
        return
    fi

    echo ""
    echo "📊 5. Load Testing with Apache Benchmark (100 requests, 10 concurrent)..."

    ab -n 100 -c 10 -t 30 "$API_URL/tasks" > "$RESULTS_DIR/ab_test_$TIMESTAMP.txt" 2>&1

    echo "✅ Apache Benchmark results saved to ab_test_$TIMESTAMP.txt"
    tail -20 "$RESULTS_DIR/ab_test_$TIMESTAMP.txt"
}

# Function for concurrent load test
load_test_concurrent() {
    echo ""
    echo "📊 6. Concurrent Load Test (50 parallel requests)..."

    RESULTS_FILE="$RESULTS_DIR/concurrent_$TIMESTAMP.txt"
    > "$RESULTS_FILE"

    START_TIME=$(date +%s%N)

    for i in {1..50}; do
        (curl -s "$API_URL/tasks" > /dev/null 2>&1) &
    done

    wait

    END_TIME=$(date +%s%N)
    TOTAL_TIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    echo "✅ 50 concurrent requests completed in ${TOTAL_TIME_MS}ms"
    echo "Concurrent requests: 50" >> "$RESULTS_FILE"
    echo "Total time: ${TOTAL_TIME_MS}ms" >> "$RESULTS_FILE"
    echo "Avg time per request: $(echo "scale=2; $TOTAL_TIME_MS / 50" | bc)ms" >> "$RESULTS_FILE"
}

# Cleanup
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    docker-compose down
}

trap cleanup EXIT

# Run all benchmarks
measure_startup
measure_resources
test_endpoints
load_test_curl
load_test_ab
load_test_concurrent

echo ""
echo "=================================="
echo "✅ Benchmark Complete!"
echo "📁 Results saved to: $RESULTS_DIR/"
echo "📊 View results:"
ls -lh "$RESULTS_DIR"/*_$TIMESTAMP.*
