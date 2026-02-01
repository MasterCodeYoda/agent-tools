# Operations: Concurrency, Disposability & Parity

Factors 8, 9, and 10 address how applications scale and operate reliably.

## Factor 8: Concurrency

> Scale out via the process model

### The Principle

Twelve-factor apps scale horizontally by running multiple processes, not by threading within a single process. Different work types run as different process types.

### The Unix Process Model

Instead of one monolithic process doing everything, decompose work:

```
┌─────────────────────────────────────────────────────────┐
│                    Application                           │
├──────────────┬──────────────┬──────────────┬────────────┤
│   web (x4)   │  worker (x2) │ scheduler(x1)│ mailer (x1)│
│              │              │              │            │
│ HTTP requests│ Background   │ Cron jobs    │ Email      │
│              │ jobs         │              │ sending    │
└──────────────┴──────────────┴──────────────┴────────────┘
```

### Process Types (Procfile)

```procfile
web: gunicorn app:application --workers 4 --bind 0.0.0.0:$PORT
worker: celery -A tasks worker --concurrency 4
scheduler: celery -A tasks beat
mailer: python -m myapp.mailer
```

Each line defines a process type. Scale each independently.

### Scaling by Process Type

| Process Type | Workload | Scaling Factor |
|--------------|----------|----------------|
| `web` | HTTP requests | Request volume |
| `worker` | Background jobs | Queue depth |
| `scheduler` | Timed tasks | Usually 1 (leader) |
| `mailer` | Email delivery | Email queue |

```yaml
# Kubernetes: Scale process types independently
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 4  # Scale web processes
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
spec:
  replicas: 2  # Fewer workers
```

### Process Concurrency vs. Thread Concurrency

Twelve-factor prefers process-level concurrency because:
- Processes are isolated—one crash doesn't affect others
- Memory is isolated—no shared state bugs
- OS handles scheduling and resource limits
- Scaling is explicit and observable

Internal threading is fine for I/O-bound work within a process:

```python
# Gunicorn with async workers
gunicorn app:application --workers 4 --worker-class uvicorn.workers.UvicornWorker
```

This runs 4 processes, each handling concurrent async I/O.

### When to Use Multiple Process Types

| Scenario | Process Type Solution |
|----------|----------------------|
| HTTP requests + background jobs | `web` + `worker` |
| Scheduled tasks | `scheduler` (single instance) |
| Long-running connections (WebSocket) | `websocket` (separate from `web`) |
| CPU-intensive work | `compute` (separate pool) |

---

## Factor 9: Disposability

> Maximize robustness with fast startup and graceful shutdown

### The Principle

Processes should start quickly and shut down gracefully. This enables:
- Rapid elastic scaling
- Fast deploys and rollbacks
- Robust handling of crashes

### Fast Startup

Target: **under 10 seconds** from launch to ready.

**What slows startup:**
- Large dependency loading (ML models, heavy frameworks)
- Database migrations (should be separate process)
- Waiting for backing service connections without timeouts
- Synchronous initialization of optional features

**Strategies for fast startup:**
```python
# Lazy loading for expensive resources
_model = None

def get_model():
    global _model
    if _model is None:
        _model = load_ml_model()  # Only on first use
    return _model
```

```python
# Connection pooling with timeouts
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_timeout=5,  # Don't wait forever
    connect_args={"connect_timeout": 5},
)
```

### Graceful Shutdown

When receiving `SIGTERM`, processes should:
1. Stop accepting new work
2. Complete in-flight requests/jobs
3. Close connections cleanly
4. Exit

**Web server example (Python):**
```python
import signal
import sys

def handle_sigterm(signum, frame):
    print("SIGTERM received, shutting down gracefully...")
    # Stop accepting new requests
    server.stop_accepting()
    # Wait for in-flight requests (with timeout)
    server.shutdown(timeout=30)
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)
```

**Worker example (Celery):**
```python
# Celery handles SIGTERM by default:
# - Stops accepting new tasks
# - Waits for current tasks to complete
# - Configure with --soft-time-limit and --time-limit
```

### Crash-Only Design

Assume processes can crash at any time. Design for it:

```python
# Idempotent operations
def process_order(order_id):
    order = db.get(order_id)

    if order.status == "processed":
        return  # Already done, idempotent

    # Do the work...
    process_payment(order)

    # Mark complete
    order.status = "processed"
    db.save(order)
```

### Kubernetes Lifecycle

```yaml
spec:
  containers:
    - name: app
      lifecycle:
        preStop:
          exec:
            command: ["/bin/sh", "-c", "sleep 5"]  # Grace period
      livenessProbe:
        httpGet:
          path: /health
          port: 8000
        initialDelaySeconds: 5
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /ready
          port: 8000
        initialDelaySeconds: 3
        periodSeconds: 5
  terminationGracePeriodSeconds: 30
```

---

## Factor 10: Dev/Prod Parity

> Keep development, staging, and production as similar as possible

### The Principle

Historically, there were gaps between environments:

| Gap | Description | Risk |
|-----|-------------|------|
| **Time** | Code written weeks before deploy | Integration issues discovered late |
| **Personnel** | Devs write, ops deploy | Knowledge gaps, blame games |
| **Tools** | SQLite dev, PostgreSQL prod | Behavior differences cause bugs |

### The Goal: Minimize All Gaps

| Traditional | Twelve-Factor |
|-------------|---------------|
| Deploy weekly | Deploy hourly/daily |
| Different teams for dev/ops | Same team (DevOps) |
| Different backing services | Same backing services |

### Backing Service Parity

**Wrong: Different services per environment**
```python
# BAD: Different database in dev
if os.environ.get("ENV") == "development":
    DATABASE_URL = "sqlite:///dev.db"  # Different behavior!
else:
    DATABASE_URL = os.environ["DATABASE_URL"]  # PostgreSQL
```

Problems:
- SQLite and PostgreSQL have different SQL dialects
- Transaction behavior differs
- Type handling differs
- Bugs appear only in production

**Right: Same services everywhere**
```yaml
# docker-compose.yml for local development
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_PASSWORD: devpassword

  redis:
    image: redis:7

  app:
    build: .
    environment:
      DATABASE_URL: postgres://postgres:devpassword@db:5432/myapp_dev
      REDIS_URL: redis://redis:6379
```

### Modern Tooling for Parity

| Service | Local Solution |
|---------|---------------|
| PostgreSQL | Docker container, Postgres.app |
| Redis | Docker container, redis-server |
| Elasticsearch | Docker container |
| S3 | MinIO (S3-compatible) |
| SQS | LocalStack, ElasticMQ |
| DynamoDB | LocalStack, DynamoDB Local |

### What Can Differ

Some differences are acceptable:

| Aspect | Dev | Prod | Acceptable |
|--------|-----|------|------------|
| Database engine | PostgreSQL | PostgreSQL | ✓ Same |
| Database size | Small dataset | Large dataset | ✓ Expected |
| Replicas | 1 | 3+ | ✓ Config |
| TLS | Optional | Required | ✓ Security |
| Resources | Limited | Scaled | ✓ Infra |

What must NOT differ:
- Database engine (Postgres vs MySQL)
- Queue system (Redis vs RabbitMQ)
- Search engine (Elasticsearch vs Algolia)
- Fundamental behavior of backing services

### Testing for Parity

```python
# Integration tests run against real services
@pytest.fixture(scope="session")
def database():
    # Spin up PostgreSQL container for tests
    with PostgresContainer("postgres:15") as postgres:
        yield postgres.get_connection_url()

def test_complex_query(database):
    # Tests against real PostgreSQL, not SQLite mock
    engine = create_engine(database)
    result = engine.execute(complex_window_function_query)
    assert result.fetchone() is not None
```

### Verification Checklist

- [ ] Application scales by adding processes, not threads
- [ ] Different work types run as separate process types
- [ ] Process startup time is under 10 seconds
- [ ] Graceful shutdown on SIGTERM (drain connections)
- [ ] Operations are idempotent (safe to retry)
- [ ] Development uses same backing service types as production
- [ ] No SQLite-in-dev, PostgreSQL-in-prod patterns
- [ ] Integration tests run against real services
