# 12 Factors: Quick Reference

A scannable reference for all 12 factors. For detailed guidance, see the topic-specific documents.

## Factor Summary Table

| # | Factor | One-Liner | Do This | Avoid This |
|---|--------|-----------|---------|------------|
| 1 | Codebase | One repo per app | Single repo with multiple deploys | Multiple repos for one app, or one repo for multiple apps |
| 2 | Dependencies | Explicit declaration | `requirements.txt`, `package.json`, lock files | System-wide packages, undeclared tools |
| 3 | Config | Environment variables | `DATABASE_URL`, secrets in env | Hardcoded values, config files in repo |
| 4 | Backing Services | Attached resources | Connection strings from config | Hardcoded service locations |
| 5 | Build/Release/Run | Strict separation | CI builds artifact, CD deploys it | Building in production, runtime patches |
| 6 | Processes | Stateless | Store state in backing services | Local file storage, sticky sessions |
| 7 | Port Binding | Self-contained | App binds to port directly | Rely on external web server injection |
| 8 | Concurrency | Process model | Scale by process type (web, worker) | Threading for all scaling |
| 9 | Disposability | Fast, graceful | Quick startup, SIGTERM handling | Long startup, ungraceful shutdown |
| 10 | Dev/Prod Parity | Keep similar | Same backing services, same versions | SQLite in dev, Postgres in prod |
| 11 | Logs | Event streams | Write to stdout, aggregate externally | Writing to log files in app |
| 12 | Admin | One-off processes | Run in same environment as app | SSH into prod, manual scripts |

## Compliance Checklist

### Codebase & Dependencies (Factors 1-2)
- [ ] Application has a single codebase tracked in version control
- [ ] All dependencies are explicitly declared with versions
- [ ] Lock files are committed (`package-lock.json`, `poetry.lock`, etc.)
- [ ] No reliance on system-installed packages or tools

### Configuration (Factors 3-4)
- [ ] No secrets or environment-specific config in codebase
- [ ] All config available through environment variables
- [ ] Backing services (DB, cache, queue) are configured via URLs
- [ ] Backing services can be swapped without code changes

### Deployment (Factors 5-7)
- [ ] Build produces immutable artifact (container image, bundle)
- [ ] Release combines build artifact with environment config
- [ ] Application binds directly to port (no external injection)
- [ ] Processes are stateless—no local session state

### Operations (Factors 8-10)
- [ ] Application scales horizontally by adding instances
- [ ] Startup time is under 10 seconds
- [ ] Graceful shutdown on SIGTERM (drain connections, finish work)
- [ ] Development uses same backing service types as production

### Observability (Factors 11-12)
- [ ] Logs written to stdout/stderr as event streams
- [ ] No application-managed log files
- [ ] Admin tasks run as one-off processes in app environment
- [ ] Migrations and scripts are versioned with application code

## Factor Groupings

| Concern | Factors | Reference |
|---------|---------|-----------|
| Code Organization | 1 (Codebase), 2 (Dependencies) | [code-organization.md](code-organization.md) |
| Configuration | 3 (Config), 4 (Backing Services) | [configuration.md](configuration.md) |
| Deployment | 5 (Build/Release/Run), 6 (Processes), 7 (Port Binding) | [deployment.md](deployment.md) |
| Operations | 8 (Concurrency), 9 (Disposability), 10 (Dev/Prod Parity) | [operations.md](operations.md) |
| Observability | 11 (Logs), 12 (Admin Processes) | [observability.md](observability.md) |

## Quick Diagnostics

**"It works locally but not in production"**
- Check Factor 3 (Config) - environment-specific values in code?
- Check Factor 10 (Parity) - different backing services?
- Check Factor 2 (Dependencies) - undeclared system tools?

**"Deployments cause downtime"**
- Check Factor 9 (Disposability) - slow startup?
- Check Factor 6 (Processes) - sticky sessions or local state?
- Check Factor 5 (Build/Release/Run) - building during deploy?

**"Can't scale horizontally"**
- Check Factor 6 (Processes) - local file storage?
- Check Factor 8 (Concurrency) - single-process architecture?
- Check Factor 4 (Backing Services) - coupled to single instance?

**"Hard to debug in production"**
- Check Factor 11 (Logs) - logs in files or stdout?
- Check Factor 12 (Admin) - can you run one-off processes?
- Check Factor 10 (Parity) - can you reproduce locally?
