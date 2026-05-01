# CRUD Benchmark App (Docker vs VM Research Experiment)

## Overview

This application was specifically developed to support a **Distributed Computing research experiment** comparing performance between:

# CRUD Benchmark

Comprehensive README for the `crud-benchmark` research project. This repository implements a small, intentionally simple CRUD API backed by SQLite, packaged for quick experiments comparing container and VM behavior.

Contents

- **Purpose**: Provide a lightweight, reproducible app for measuring startup time, resource usage, latency, and throughput across virtualization environments.
- **Stack**: Node.js (Express) + SQLite
- **Deployment**: Local, Docker (via Docker Compose)

Key Files

- [package.json](package.json) — project metadata and dependencies
- [Dockerfile](Dockerfile) — image build instructions
- [docker-compose.yml](docker-compose.yml) — compose setup for quick runs
- [index.js](index.js) — API entrypoint (main server)
- [init.sql](init.sql) — optional DB initialization script

Prerequisites

- Docker & Docker Compose (for container runs)
- Node.js (v16+) and a package manager (`pnpm` recommended but `npm` works)
- Optional: `ab` (ApacheBench) or `wrk` for load testing

Quick Start — Docker (recommended for reproducible benchmarks)

1. Build and start:

```bash
docker compose build
docker compose up
```

2. The API will be available at:

```text
http://localhost:3000
```

Local Dev (without Docker)

1. Install dependencies:

```bash
pnpm install
# or
npm install
```

2. Start the server:

```bash
node index.js
```

API Reference

All endpoints use JSON. Base URL: `http://localhost:3000`

Endpoints

- POST /tasks — create a task
- GET /tasks — list tasks
- GET /tasks/:id — get one task
- PUT /tasks/:id — update a task
- DELETE /tasks/:id — delete a task

Example: Create a task

```bash
curl -X POST http://localhost:3000/tasks \
	-H "Content-Type: application/json" \
	-d '{"title":"Finish Research Paper"}'
```

Database

- The app uses SQLite for simplicity and reproducibility.
- If present, `init.sql` can be used to pre-populate or reset schema; otherwise the app will create required tables on startup.

Benchmarking Guide — Suggested Methodology

Goals

- Measure startup time, resource overhead, latency, and throughput differences between containers and VMs.

General notes

- Run each test multiple times (3–5) and report mean and variance.
- Ensure system noise is minimized (close unrelated apps, isolate CPU/IO when possible).

1. Startup time

Measure time from `docker compose up --build` to when the API responds to health check requests.

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
