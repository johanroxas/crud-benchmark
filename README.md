# CRUD Benchmark App

Lightweight CRUD API for benchmarking performance across virtualization environments (containers vs VMs). Built with Node.js (Express) + SQLite for reproducible, real-world testing.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Running the App](#running-the-app)
- [API Reference](#api-reference)
- [Development Workflow](#development-workflow)
- [Benchmarking](#benchmarking)
- [Troubleshooting](#troubleshooting)

## Overview

This application supports **Distributed Computing research experiments** comparing performance between Docker containers and VMs. It provides:

- ✅ Lightweight CRUD operations backed by SQLite
- ✅ Reproducible, containerized deployment
- ✅ Automated benchmarking tools for startup time, resource usage, and response testing
- ✅ Load testing capabilities (sequential and concurrent)

**Stack**: Node.js (Express) + SQLite + Docker Compose

## Prerequisites

### Required

- **Docker** & **Docker Compose** ([install](https://docs.docker.com/get-docker/))
- **Node.js** v20+ ([install](https://nodejs.org))
- **pnpm** v10+ ([install](https://pnpm.io)) or npm

### Optional (for benchmarking)

- **Apache Bench** (ab) — `brew install httpd` on macOS
- **curl** (usually pre-installed)

## Project Structure

```
.
├── index.js              # Main Express app & API endpoints
├── package.json          # Dependencies & scripts
├── Dockerfile            # Container image definition
├── docker-compose.yml    # Docker Compose configuration
├── benchmark.sh          # Full benchmarking suite
├── simple-load-test.sh   # Quick load test (100 requests)
├── README.md             # This file
└── tasks.db              # SQLite database (generated)
```

## Setup & Installation

### 1. Clone & Install

```bash
# Clone the repository
git clone https://github.com/johanroxas/crud-benchmark.git
cd crud-benchmark

# Install dependencies
```

pnpm install
npm install

### 2. Verify Installation

```bash
# Check Node.js version
node --version

# Check pnpm version
pnpm --version

# Check Docker
docker --version
docker-compose --version
```

## Running the App

### Option A: Docker (Recommended for Benchmarking)

This is the preferred method for consistent, reproducible results.

```bash
# Build the container image
docker-compose build

# Start the app (runs with nodemon for auto-reload)
docker-compose up

# View logs
docker-compose logs -f

# Stop the app
docker-compose down
```

The API will be available at: **http://localhost:3000**

### Option B: Local Development (Without Docker)

```bash
# Install dependencies
pnpm install

# Start with hot-reload via nodemon
pnpm run dev

# Or run directly
node index.js
```

The API will be available at: **http://localhost:3000**

### Option C: Production Mode (Local)

```bash
pnpm install --prod
node index.js
```

## API Reference

**Base URL**: `http://localhost:3000`

All endpoints use JSON request/response format.

### Endpoints

| Method | Endpoint     | Description            |
| ------ | ------------ | ---------------------- |
| POST   | `/tasks`     | Create a new task      |
| GET    | `/tasks`     | List all tasks         |
| GET    | `/tasks/:id` | Get a specific task    |
| PUT    | `/tasks/:id` | Mark task as completed |
| DELETE | `/tasks/:id` | Delete a task          |

### Examples

**Create a task:**

```bash
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Finish Research Paper"}'
```

**List all tasks:**

```bash
curl http://localhost:3000/tasks
```

**Mark task as complete:**

```bash
curl -X PUT http://localhost:3000/tasks/1
```

**Delete a task:**

```bash
curl -X DELETE http://localhost:3000/tasks/1
```

## Development Workflow

### Hot Reload with Docker

The app automatically restarts on file changes via `nodemon`:

1. Start with `docker-compose up`
2. Edit `index.js` or other files
3. Changes apply automatically (watch logs with `docker-compose logs -f`)

### Local Development

```bash
# Terminal 1: Start the dev server
pnpm run dev

# Terminal 2: Test endpoints
curl http://localhost:3000/tasks
```

### Available npm Scripts

```bash
pnpm run dev    # Start with nodemon (auto-reload)
npm start       # Run in production mode (used by Docker)
```

## Benchmarking

### Full Benchmark Suite

Comprehensive benchmarking with startup time, resource usage, endpoints, and load testing:

```bash
chmod +x benchmark.sh
./benchmark.sh
```

**Measures:**

- ⏱️ **Startup Time**: How long until the app responds
- 💾 **Resource Usage**: CPU & RAM over 10 seconds
- 🔍 **Endpoint Response**: Individual endpoint latency
- 📈 **Sequential Load**: 100 sequential requests (curl)
- ⚡ **Apache Benchmark**: 100 concurrent requests (if `ab` installed)
- 🚀 **Concurrent Load**: 50 parallel requests

**Output**: Results saved to `./benchmark-results/` with timestamps

### Quick Load Test (100 Requests)

Fast load test showing response stability:

```bash
chmod +x simple-load-test.sh
./simple-load-test.sh http://localhost:3000 100
```

**Output**:

```
==================================
📊 RESULTS
==================================
Total Requests: 100
Successful: 100
Failed: 0
Success Rate: 100.0%

Response Times (ms):
  Min:     2ms
  Max:     15ms
  Avg:     5.23ms
  Total:   523ms

Requests/sec: 191.05
==================================
```

### Manual Load Testing with Apache Bench

If Apache Bench is installed:

```bash
# Install Apache Bench
brew install httpd

# Run 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost:3000/tasks
```

### Manual Load Testing with curl Loop

Simple loop for quick testing:

```bash
# 50 sequential requests
for i in {1..50}; do curl http://localhost:3000/tasks; done

# Parallel requests (50 concurrent)
for i in {1..50}; do (curl http://localhost:3000/tasks &); done
wait
```

### Benchmark Methodology

For consistent, reproducible results:

1. **Run multiple times**: Execute each benchmark 3–5 times
2. **Minimize noise**: Close unrelated apps, isolate system resources
3. **Record baseline**: Save results before making changes
4. **Compare**: Use timestamps in results folder to compare runs

**Example workflow:**

```bash
# Baseline run
./benchmark.sh

# Make a change to index.js

# Test run
./benchmark.sh

# Compare results/ folder
ls -la benchmark-results/
```

## Database

- **Type**: SQLite (file-based, no server needed)
- **File**: `tasks.db` (auto-created on first run)
- **Schema**: Auto-created by app on startup
- **Initialization**: Optional `init.sql` for pre-population

## Troubleshooting

### Port 3000 Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process (replace PID)
kill -9 <PID>

# Or use Docker Compose to clean up
docker-compose down
```

### Docker Container Won't Start

```bash
# View detailed logs
docker-compose logs app

# Rebuild from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### nodemon Not Found

```bash
# Reinstall dev dependencies
pnpm install
```

### Benchmarks Not Running

```bash
# Make scripts executable
chmod +x benchmark.sh simple-load-test.sh

# Check if curl is installed
which curl

# Check if Apache Bench is available (optional)
which ab
```

### Database Locked Error

```bash
# Remove the old database
rm -f tasks.db

# Restart the app
docker-compose down
docker-compose up
```

```bash
time docker compose up --build
# then poll endpoint until healthy
```

2. Resource usage

Monitor with `docker stats` (containers) or host tooling (VM):

```bash
docker stats
```

Record CPU and memory at idle and under load.

3. Latency & throughput

Use `ab` or `wrk` for load testing. Example with ApacheBench:

```bash
ab -n 1000 -c 50 http://localhost:3000/tasks
```

`wrk` example:

```bash
wrk -t12 -c200 -d30s http://localhost:3000/tasks
```

Interpretation

- Note average response time, p95/p99 latencies, requests/sec, and errors.
- Combine metrics with resource usage to reason about efficiency.

Seeding Data

Populate DB before read-heavy tests to produce realistic datasets:

```bash
for i in $(seq 1 500); do
	curl -s -X POST http://localhost:3000/tasks \
		-H "Content-Type: application/json" \
		-d "{\"title\":\"Task $i\"}" >/dev/null
done
```

Reproducibility Tips

- Use Docker Compose to pin image configuration.
- Record exact host kernel, Docker version, and resource limits (CPU/memory) used during tests.
- When comparing to VMs, match CPU/core counts and memory where possible.

Troubleshooting

- If port 3000 is in use, set `PORT` env var or change compose mapping.
- Check container logs:

```bash
docker compose logs -f
```
