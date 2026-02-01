# Deployment: Build, Release, Run & Processes

Factors 5, 6, and 7 address how applications are built, deployed, and executed.

## Factor 5: Build, Release, Run

> Strictly separate build, release, and run stages

### The Principle

The transformation from codebase to running application happens in three stages:

```
┌─────────┐      ┌─────────┐      ┌─────────┐
│  BUILD  │ ───► │ RELEASE │ ───► │   RUN   │
│         │      │         │      │         │
│ Code +  │      │ Build + │      │ Release │
│ Deps    │      │ Config  │      │ Running │
└─────────┘      └─────────┘      └─────────┘
   ci/cd           deploy          runtime
```

### Stage Responsibilities

| Stage | Input | Output | Mutability |
|-------|-------|--------|------------|
| **Build** | Code + dependencies | Executable artifact | Triggered by developer |
| **Release** | Build + config | Deployable release | Immutable, versioned |
| **Run** | Release | Running processes | Managed by platform |

### Build Stage

Converts code into an executable bundle. Triggered when developers push code.

**Container build example:**
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production image
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/server.js"]
```

The output is a container image—an immutable artifact.

### Release Stage

Combines build artifact with environment-specific config to create a release.

```yaml
# Kubernetes deployment - combines image with config
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:v2.1.0  # Build artifact
          envFrom:
            - configMapRef:
                name: app-config  # Environment config
            - secretRef:
                name: app-secrets
```

Releases are immutable. To change config, create a new release.

### Run Stage

Executes the release as one or more processes. Managed by the platform (Kubernetes, container runtime, PaaS).

```bash
# Platform runs the release
docker run -e DATABASE_URL=... myapp:v2.1.0
```

### Anti-Patterns

**Building in production**
```bash
# BAD: Cloning and building on production server
ssh prod-server
git pull
npm install
npm run build
pm2 restart app
```

**Runtime code changes**
```bash
# BAD: Patching running code
ssh prod-server
vim /app/src/handlers.js  # Never do this
```

**Config embedded in build**
```dockerfile
# BAD: Config baked into image
ENV DATABASE_URL=postgres://prod-db...
```

### Release Versioning

Every release should have a unique identifier:

```
myapp:v2.1.0           # Semantic version
myapp:20240115-abc123  # Date + commit
myapp:abc123           # Commit hash only
```

This enables:
- Rollback to previous releases
- Audit trail of deployments
- Correlation between code and runtime

---

## Factor 6: Processes

> Execute the app as one or more stateless processes

### The Principle

Twelve-factor processes are stateless and share-nothing. Any data that needs to persist must be stored in a stateful backing service.

### Stateless Means No Local State

**Wrong: Local file storage**
```python
# BAD: File stored on local disk
def upload_avatar(user_id, file):
    path = f"/uploads/{user_id}/avatar.png"
    file.save(path)
    return path
```

If the process dies or scales, the file is lost or unreachable.

**Right: Backing service storage**
```python
# GOOD: File stored in S3
def upload_avatar(user_id, file):
    key = f"avatars/{user_id}/avatar.png"
    s3.upload_fileobj(file, bucket, key)
    return f"https://{bucket}.s3.amazonaws.com/{key}"
```

### Stateless Means No Sticky Sessions

**Wrong: In-memory sessions**
```python
# BAD: Session stored in process memory
sessions = {}

@app.route("/login")
def login():
    session_id = create_session_id()
    sessions[session_id] = {"user_id": user.id}
    return {"session_id": session_id}
```

This breaks with multiple processes—requests may hit different instances.

**Right: External session storage**
```python
# GOOD: Session stored in Redis
@app.route("/login")
def login():
    session_id = create_session_id()
    redis.setex(f"session:{session_id}", 3600, json.dumps({"user_id": user.id}))
    return {"session_id": session_id}
```

### What About Caching?

In-memory caches (like process-local dicts) are acceptable for **performance optimization** only if:
- The app works correctly without the cache
- Cache misses hit the backing service
- No cache invalidation coordination is needed across processes

```python
# Acceptable: LRU cache for expensive computation
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_user_permissions(user_id):
    # Falls back to database on cache miss
    return db.query(Permission).filter_by(user_id=user_id).all()
```

For coordination or shared state, use Redis or similar.

### Process Types

Applications often have multiple process types:

```
web: gunicorn app:application -w 4 -b 0.0.0.0:$PORT
worker: celery -A tasks worker
scheduler: celery -A tasks beat
```

Each type can scale independently.

---

## Factor 7: Port Binding

> Export services via port binding

### The Principle

The twelve-factor app is completely self-contained. It doesn't rely on runtime injection of a webserver. Instead, the app binds to a port and listens for requests.

### Self-Contained HTTP Service

**Python (Flask/Gunicorn)**
```python
# app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return "Hello"

if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
```

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

**Node.js**
```javascript
const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => res.send("Hello"));
app.listen(port, "0.0.0.0", () => {
  console.log(`Listening on port ${port}`);
});
```

**Go**
```go
func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    http.HandleFunc("/", handler)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

### Port Binding Enables Service Composition

One app's exported service becomes another app's backing service:

```
┌──────────────┐     HTTP      ┌──────────────┐
│   Frontend   │ ────────────► │   API        │
│   :3000      │               │   :8000      │
└──────────────┘               └──────────────┘
                                     │
                                     │ HTTP
                                     ▼
                               ┌──────────────┐
                               │   Auth       │
                               │   :8001      │
                               └──────────────┘
```

### Modern Context: Container Networking

In Kubernetes, port binding maps to container ports:

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: app
      image: myapp:v1
      ports:
        - containerPort: 8000  # App binds to 8000
      env:
        - name: PORT
          value: "8000"
---
apiVersion: v1
kind: Service
spec:
  ports:
    - port: 80           # Service port
      targetPort: 8000   # Container port
```

### Anti-Patterns

**Relying on external web server**
```apache
# BAD: Apache config injecting app
<VirtualHost *:80>
    WSGIScriptAlias / /var/www/app/app.wsgi
</VirtualHost>
```

The app should include its own WSGI server (Gunicorn, uWSGI).

**Hardcoded ports**
```python
# BAD: Port not configurable
app.run(port=8000)  # What if 8000 is taken?
```

```python
# GOOD: Port from environment
app.run(port=int(os.environ.get("PORT", 8000)))
```

### Verification Checklist

- [ ] Build produces immutable artifact (container image, bundle)
- [ ] Config is not embedded in build artifacts
- [ ] Releases are versioned and immutable
- [ ] No building or patching at runtime
- [ ] Processes store no local state (files, sessions)
- [ ] Session state in external store (Redis, database)
- [ ] Application binds to configurable port
- [ ] No reliance on external web server injection
