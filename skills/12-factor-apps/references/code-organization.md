# Code Organization: Codebase & Dependencies

Factors 1 and 2 establish the foundation for reproducible, portable applications.

## Factor 1: Codebase

> One codebase tracked in revision control, many deploys

### The Principle

A twelve-factor app has exactly one codebase. Multiple deploys (production, staging, development) share that codebase but may run different versions.

### Correct Patterns

**One app = One repository**
```
my-app/
├── src/
├── tests/
├── Dockerfile
└── package.json
```

**Monorepo with distinct apps** (acceptable when apps share infrastructure)
```
platform/
├── apps/
│   ├── api/          # Separate deployable
│   ├── web/          # Separate deployable
│   └── worker/       # Separate deployable
├── packages/
│   └── shared/       # Shared library, not deployed independently
└── infrastructure/
```

### Anti-Patterns

**Multiple repos for one application**
```
# BAD: Frontend and backend coupled but in separate repos
webapp-frontend/     # Requires specific backend version
webapp-backend/      # Requires specific frontend version
```
- Version coordination becomes manual
- Atomic changes impossible
- Integration testing is painful

**One repo, multiple unrelated applications**
```
# BAD: Unrelated apps sharing a repo
company-code/
├── billing-service/
├── marketing-site/
└── internal-tools/
```
- Deploy coupling—changes to one affect all
- Access control complications
- CI/CD complexity

### Deploys vs. Versions

| Concept | Definition | Example |
|---------|------------|---------|
| Codebase | The repository | `github.com/org/my-app` |
| Deploy | Running instance | Production, staging, dev |
| Version | Git commit/tag | `v2.1.0`, `abc123` |

Production might run `v2.1.0` while staging runs `v2.2.0-beta`. Same codebase, different versions, different deploys.

---

## Factor 2: Dependencies

> Explicitly declare and isolate dependencies

### The Principle

Never rely on system-wide packages. Declare all dependencies explicitly and isolate them from the system.

### Dependency Declaration by Language

| Language | Declaration File | Lock File | Isolation Tool |
|----------|-----------------|-----------|----------------|
| Python | `pyproject.toml`, `requirements.txt` | `poetry.lock`, `requirements.txt` | `venv`, `poetry` |
| Node.js | `package.json` | `package-lock.json`, `yarn.lock` | `node_modules` |
| Go | `go.mod` | `go.sum` | Module system |
| Rust | `Cargo.toml` | `Cargo.lock` | Cargo |
| .NET | `*.csproj` | `packages.lock.json` | NuGet |
| Java | `pom.xml`, `build.gradle` | Varies | Maven/Gradle |

### Lock Files: Why They Matter

```bash
# Without lock file (BAD)
npm install  # Gets latest compatible versions—different on each machine

# With lock file (GOOD)
npm ci       # Installs exact versions from lock file
```

**Always commit lock files.** They ensure:
- Reproducible builds across machines and time
- Security auditing of exact versions
- Predictable behavior in CI/CD

### System Tool Dependencies

Twelve-factor apps don't shell out to system tools. If you need `curl`, `imagemagick`, or `ffmpeg`:

**Option 1: Include in container image**
```dockerfile
FROM python:3.12-slim
RUN apt-get update && apt-get install -y \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*
```

**Option 2: Use language-native alternatives**
```python
# Instead of shelling out to curl
import httpx

# Instead of shelling out to imagemagick
from PIL import Image
```

### Anti-Patterns

**Implicit system dependencies**
```python
# BAD: Assumes curl is installed
subprocess.run(["curl", "-X", "POST", url])

# GOOD: Use declared dependency
response = httpx.post(url)
```

**Undeclared development tools**
```yaml
# BAD: CI assumes tools are installed
script:
  - make build  # Assumes make is installed
  - jq .version  # Assumes jq is installed
```

```yaml
# GOOD: Container provides tools
image: node:20
script:
  - npm ci
  - npm run build
```

**Version ranges without locks**
```json
// package.json without package-lock.json
{
  "dependencies": {
    "express": "^4.18.0"  // Could be 4.18.0 or 4.21.0
  }
}
```

### Dependency Vendoring

Some teams vendor dependencies (copy into repo). This is acceptable but not required:

| Approach | Pros | Cons |
|----------|------|------|
| Lock files only | Smaller repo, standard tooling | Requires network for install |
| Vendoring | Works offline, audit trail | Larger repo, manual updates |

Go's module system supports both: `go mod download` or `go mod vendor`.

### Verification Checklist

- [ ] All runtime dependencies declared in manifest file
- [ ] Lock file committed and used in CI/CD
- [ ] No `apt-get install` or `brew install` in application startup
- [ ] Container image includes all required system tools
- [ ] Development dependencies separated from production
