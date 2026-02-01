# Configuration: Config & Backing Services

Factors 3 and 4 address how applications connect to their environment and external services.

## Factor 3: Config

> Store config in the environment

### The Principle

Configuration that varies between deploys should be stored in environment variables, not in code.

### What Is Config?

Config is anything that varies between deploys:
- Database URLs and credentials
- API keys for external services
- Feature flags for specific environments
- Host/port bindings
- Logging levels

Config is **NOT**:
- Application code
- Internal routing rules
- Framework settings that don't change per environment

### The Litmus Test

> Could you open-source the codebase without exposing credentials?

If config is properly externalized, the answer is yes.

### Environment Variables: The Interface

```bash
# Production environment
DATABASE_URL=postgres://prod-db.example.com:5432/app
REDIS_URL=redis://prod-cache.example.com:6379
LOG_LEVEL=warn
FEATURE_NEW_CHECKOUT=true

# Development environment
DATABASE_URL=postgres://localhost:5432/app_dev
REDIS_URL=redis://localhost:6379
LOG_LEVEL=debug
FEATURE_NEW_CHECKOUT=false
```

### Reading Config in Code

**Python**
```python
import os

DATABASE_URL = os.environ["DATABASE_URL"]  # Required—fails if missing
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"  # Optional with default
```

**Node.js**
```javascript
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error("DATABASE_URL required");

const debug = process.env.DEBUG === "true";
```

**Go**
```go
databaseURL := os.Getenv("DATABASE_URL")
if databaseURL == "" {
    log.Fatal("DATABASE_URL required")
}
```

### Config Validation at Startup

Fail fast if required config is missing:

```python
# config.py - Validate all config at import time
import os
from dataclasses import dataclass

@dataclass
class Config:
    database_url: str
    redis_url: str
    log_level: str = "info"

    @classmethod
    def from_env(cls) -> "Config":
        missing = []

        database_url = os.environ.get("DATABASE_URL")
        if not database_url:
            missing.append("DATABASE_URL")

        redis_url = os.environ.get("REDIS_URL")
        if not redis_url:
            missing.append("REDIS_URL")

        if missing:
            raise RuntimeError(f"Missing required config: {', '.join(missing)}")

        return cls(
            database_url=database_url,
            redis_url=redis_url,
            log_level=os.environ.get("LOG_LEVEL", "info"),
        )

config = Config.from_env()
```

### Anti-Patterns

**Config files with environment switches**
```python
# BAD: Environment logic in code
if os.environ.get("ENV") == "production":
    DATABASE_URL = "postgres://prod-db..."
elif os.environ.get("ENV") == "staging":
    DATABASE_URL = "postgres://staging-db..."
else:
    DATABASE_URL = "postgres://localhost..."
```

**Grouped config files**
```
# BAD: Config files per environment
config/
├── development.yaml
├── staging.yaml
└── production.yaml
```

These approaches don't scale—every new environment needs code changes.

**Secrets in code**
```python
# NEVER DO THIS
API_KEY = "sk-abc123..."  # Exposed in version control
```

### Modern Config Management

| Tool | Use Case | How It Works |
|------|----------|--------------|
| Docker `--env-file` | Local development | Reads `.env` file |
| Kubernetes ConfigMaps | Non-sensitive config | Mounted as env vars |
| Kubernetes Secrets | Sensitive config | Mounted as env vars (encrypted at rest) |
| AWS Parameter Store | Cloud-native apps | Fetched at startup or runtime |
| HashiCorp Vault | Secrets with rotation | Dynamic secrets, leases |
| Doppler, Infisical | SaaS secrets management | Synced to environment |

---

## Factor 4: Backing Services

> Treat backing services as attached resources

### The Principle

A backing service is any service the app consumes over the network: databases, caches, message queues, email services, etc. The app should make no distinction between local and third-party services.

### Backing Services Are Attached Resources

```
┌─────────────────────────────────────────────────────────┐
│                     Application                          │
│                                                          │
│   DATABASE_URL ──────────► PostgreSQL                    │
│   REDIS_URL ─────────────► Redis                        │
│   SMTP_URL ──────────────► Mailgun                      │
│   S3_BUCKET ─────────────► AWS S3                       │
│   QUEUE_URL ─────────────► RabbitMQ                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

Each arrow is a connection string from config. The app doesn't know (or care) whether:
- PostgreSQL is local or AWS RDS
- Redis is a container or ElastiCache
- The queue is RabbitMQ or AWS SQS

### Resource Swapping Without Code Changes

```bash
# Development: local PostgreSQL
DATABASE_URL=postgres://localhost:5432/myapp

# Staging: AWS RDS
DATABASE_URL=postgres://staging.abc123.us-east-1.rds.amazonaws.com:5432/myapp

# Production: Different AWS RDS
DATABASE_URL=postgres://prod.xyz789.us-east-1.rds.amazonaws.com:5432/myapp
```

Switching databases requires only config changes—no code deployment.

### Common Backing Service Patterns

**Database connections**
```python
from sqlalchemy import create_engine
import os

# Connection from config—works with any PostgreSQL-compatible service
engine = create_engine(os.environ["DATABASE_URL"])
```

**Cache connections**
```python
import redis
import os

# Works with local Redis, ElastiCache, Upstash, etc.
cache = redis.from_url(os.environ["REDIS_URL"])
```

**Object storage**
```python
import boto3
import os

# Works with S3, MinIO, DigitalOcean Spaces, etc.
s3 = boto3.client(
    "s3",
    endpoint_url=os.environ.get("S3_ENDPOINT"),  # Optional for S3-compatible
    aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
)
bucket = os.environ["S3_BUCKET"]
```

### Anti-Patterns

**Hardcoded service locations**
```python
# BAD: Hardcoded connection
cache = redis.Redis(host="192.168.1.100", port=6379)
```

**Service-specific code paths**
```python
# BAD: Different code for different providers
if os.environ.get("USE_AWS"):
    from myapp.storage.s3 import S3Storage as Storage
else:
    from myapp.storage.local import LocalStorage as Storage
```

Instead, use a consistent interface with provider-specific config:
```python
# GOOD: Same interface, different config
from myapp.storage import ObjectStorage
storage = ObjectStorage.from_url(os.environ["STORAGE_URL"])
```

### Health Checks for Backing Services

Applications should verify backing service connectivity at startup and expose health endpoints:

```python
def check_database():
    try:
        engine.execute("SELECT 1")
        return True
    except Exception:
        return False

def check_redis():
    try:
        cache.ping()
        return True
    except Exception:
        return False

@app.route("/health")
def health():
    checks = {
        "database": check_database(),
        "cache": check_redis(),
    }
    healthy = all(checks.values())
    return jsonify(checks), 200 if healthy else 503
```

### Verification Checklist

- [ ] No credentials or connection strings in codebase
- [ ] All config read from environment variables
- [ ] Config validated at startup (fail fast)
- [ ] Backing services referenced only by URL/connection string
- [ ] Same code works with local and remote services
- [ ] Health checks verify backing service connectivity
