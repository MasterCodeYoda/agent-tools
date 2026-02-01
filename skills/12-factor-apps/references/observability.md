# Observability: Logs & Admin Processes

Factors 11 and 12 address visibility into running applications and operational tasks.

## Factor 11: Logs

> Treat logs as event streams

### The Principle

A twelve-factor app never concerns itself with routing or storage of its output stream. It writes all logs to `stdout`/`stderr` as unbuffered event streams. The execution environment captures, routes, and stores these streams.

### Logs Are Event Streams

```
┌─────────────┐     stdout      ┌─────────────┐     ┌─────────────┐
│ Application │ ──────────────► │  Platform   │ ──► │  Aggregator │
│             │                 │  (Docker,   │     │  (Datadog,  │
│             │                 │   K8s)      │     │   ELK)      │
└─────────────┘                 └─────────────┘     └─────────────┘
```

The app writes to stdout. Everything else is the platform's responsibility.

### What Apps Should NOT Do

```python
# BAD: Application manages log files
import logging

handler = logging.FileHandler("/var/log/myapp/app.log")  # ❌
handler = logging.handlers.RotatingFileHandler(  # ❌
    "/var/log/myapp/app.log", maxBytes=10000000, backupCount=5
)
```

Problems with application-managed logs:
- Container ephemeral storage—files lost on restart
- Log rotation becomes application concern
- Multiple instances write to different files
- Aggregation requires file shipping agents

### What Apps Should Do

```python
# GOOD: Write to stdout/stderr
import logging
import sys

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s"
)

logger = logging.getLogger(__name__)
logger.info("Application started")
```

```javascript
// Node.js - console goes to stdout/stderr by default
console.log("Request received");  // stdout
console.error("Error occurred");  // stderr

// Or use a structured logger
const pino = require("pino");
const logger = pino({ level: "info" });
logger.info({ requestId: "abc" }, "Request received");
```

### Structured Logging

Structured logs (JSON) are easier to parse and query:

```python
import json
import sys
from datetime import datetime

def log_event(level, message, **context):
    event = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "message": message,
        **context,
    }
    print(json.dumps(event), file=sys.stdout)

log_event("info", "Order processed", order_id="12345", user_id="u-789")
```

Output:
```json
{"timestamp": "2024-01-15T10:30:00.000Z", "level": "info", "message": "Order processed", "order_id": "12345", "user_id": "u-789"}
```

### Platform Log Aggregation

| Platform | How Logs Are Captured |
|----------|----------------------|
| Docker | `docker logs` captures stdout/stderr |
| Kubernetes | kubelet captures container output |
| Heroku | Logplex aggregates dyno output |
| AWS ECS/Fargate | CloudWatch Logs via awslogs driver |
| Serverless (Lambda) | CloudWatch Logs automatic |

```yaml
# Kubernetes: No log config in app, platform handles it
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: app
      image: myapp:v1
      # Logs automatically captured by kubelet
      # Fluentd/Fluent Bit forwards to aggregator
```

### Log Levels and When to Use Them

| Level | Use For | Example |
|-------|---------|---------|
| `error` | Unexpected failures requiring attention | Database connection failed |
| `warn` | Degraded operation, potential issues | Retry attempt, cache miss |
| `info` | Significant business events | Order created, user logged in |
| `debug` | Detailed diagnostic info | SQL queries, request details |

---

## Factor 12: Admin Processes

> Run admin/management tasks as one-off processes

### The Principle

One-off administrative tasks (database migrations, console sessions, one-time scripts) should run in identical environments to the app's regular processes.

### Admin Tasks Run Against a Release

```
┌─────────────────────────────────────────────────────────┐
│                     Release v2.1.0                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Long-running processes:                                 │
│    web (x4)       worker (x2)       scheduler (x1)      │
│                                                          │
│  One-off admin processes:                                │
│    migrate        console           data-cleanup         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

Admin processes use the same codebase and config as long-running processes.

### Common Admin Tasks

**Database migrations**
```bash
# Run migration as one-off process
kubectl run migrate --image=myapp:v2.1.0 --rm -it --restart=Never \
  --env-from=configmap/app-config \
  --env-from=secret/app-secrets \
  -- python manage.py migrate
```

**Interactive console**
```bash
# Django shell with production config
kubectl exec -it deployment/web -- python manage.py shell

# Rails console
kubectl exec -it deployment/web -- rails console
```

**Data repair scripts**
```bash
# One-time data cleanup
kubectl run cleanup --image=myapp:v2.1.0 --rm -it --restart=Never \
  -- python -m scripts.cleanup_orphaned_records
```

### Anti-Patterns

**SSH into production servers**
```bash
# BAD: Manual server access
ssh prod-server
cd /var/www/app
python manage.py shell
```

Problems:
- Environment may differ from app runtime
- No audit trail
- Can't scale or reproduce

**Scripts outside version control**
```bash
# BAD: Ad-hoc scripts
ssh prod-server
cat > fix_data.py << 'EOF'
# one-time fix...
EOF
python fix_data.py
```

### Correct Patterns

**Migrations in CI/CD**
```yaml
# GitHub Actions: Run migration as part of deploy
- name: Run migrations
  run: |
    kubectl run migrate --image=$IMAGE --rm --restart=Never \
      --env-from=configmap/app-config \
      -- python manage.py migrate --no-input

- name: Deploy new version
  run: |
    kubectl set image deployment/web app=$IMAGE
```

**Scripts in codebase**
```
myapp/
├── src/
├── scripts/
│   ├── cleanup_orphaned_records.py
│   ├── backfill_user_names.py
│   └── generate_report.py
└── ...
```

```python
# scripts/cleanup_orphaned_records.py
"""
One-off script to clean up orphaned records.
Run with: python -m scripts.cleanup_orphaned_records
"""
import os
from myapp.database import get_engine
from myapp.config import Config

def main():
    config = Config.from_env()
    engine = get_engine(config.database_url)

    with engine.begin() as conn:
        result = conn.execute("""
            DELETE FROM uploads
            WHERE user_id NOT IN (SELECT id FROM users)
        """)
        print(f"Deleted {result.rowcount} orphaned uploads")

if __name__ == "__main__":
    main()
```

### Kubernetes Jobs for Admin Tasks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: myapp:v2.1.0
          command: ["python", "-m", "scripts.migrate_data"]
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: app-secrets
  backoffLimit: 0  # Don't retry on failure
```

### REPL and Console Access

For debugging, prefer tooling that connects to the app environment:

```bash
# Django shell in Kubernetes
kubectl exec -it deploy/web -- python manage.py shell

# Node.js REPL with app context
kubectl exec -it deploy/web -- node -e "require('./src/app')"

# Elixir remote console
kubectl exec -it deploy/web -- ./bin/myapp remote
```

### Verification Checklist

- [ ] Application writes logs to stdout/stderr
- [ ] No application-managed log files
- [ ] Logs are structured (JSON) for parseability
- [ ] Admin scripts are in version control
- [ ] Migrations run as one-off processes
- [ ] Admin tasks use same environment as app
- [ ] No SSH into production for ad-hoc scripts
- [ ] REPL access via kubectl exec or equivalent
