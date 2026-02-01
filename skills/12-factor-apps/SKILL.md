# 12-Factor Apps

```yaml
name: 12-factor-apps
description: Cloud-native application design principles for portable, scalable, maintainable systems
```

## When to Use This Skill

- **Building cloud-native applications** that need to run across different environments
- **Preparing for containerization** (Docker, Kubernetes) or serverless deployment
- **Diagnosing deployment issues** related to configuration, state, or environment coupling
- **Evaluating application architecture** for production readiness
- **Onboarding teams** to modern deployment practices

## Philosophy

The 12-factor methodology emerged from Heroku's experience deploying thousands of applications. It codifies patterns that make applications:

- **Portable**: Run identically in development, staging, and production
- **Scalable**: Scale horizontally by adding process instances
- **Maintainable**: Clear boundaries between concerns
- **Resilient**: Handle failures gracefully through statelessness and disposability

These aren't arbitrary rules—each factor addresses a specific class of problems encountered at scale.

## The 12 Factors at a Glance

| # | Factor | Principle | Why It Matters |
|---|--------|-----------|----------------|
| 1 | **Codebase** | One codebase, many deploys | Eliminates "works on my machine" drift |
| 2 | **Dependencies** | Explicitly declare and isolate | Reproducible builds, no implicit system dependencies |
| 3 | **Config** | Store in environment | Secrets stay out of code, environment-specific settings |
| 4 | **Backing Services** | Treat as attached resources | Swap databases, caches, queues without code changes |
| 5 | **Build, Release, Run** | Strictly separate stages | Immutable releases, traceable deployments |
| 6 | **Processes** | Execute as stateless processes | Horizontal scaling, crash recovery |
| 7 | **Port Binding** | Export services via port binding | Self-contained services, no runtime injection |
| 8 | **Concurrency** | Scale via the process model | CPU-bound vs I/O-bound process types |
| 9 | **Disposability** | Fast startup, graceful shutdown | Elastic scaling, zero-downtime deploys |
| 10 | **Dev/Prod Parity** | Keep environments similar | Catch issues early, reduce deployment surprises |
| 11 | **Logs** | Treat as event streams | Centralized aggregation, structured observability |
| 12 | **Admin Processes** | Run as one-off processes | Migrations, scripts run in same environment |

For detailed implementation guidance, see [factors-overview.md](references/factors-overview.md).

## Modern Context

The 12-factor methodology predates containers and Kubernetes, but its principles map directly:

| 12-Factor Concept | Modern Implementation |
|-------------------|----------------------|
| Stateless processes | Container ephemeral storage |
| Config in environment | ConfigMaps, Secrets, Parameter Store |
| Port binding | Container networking, service mesh |
| Disposability | Pod lifecycle, liveness/readiness probes |
| Concurrency | Horizontal Pod Autoscaler, replica sets |
| Build/Release/Run | CI/CD pipelines, GitOps, container registries |

**Serverless** embraces these factors implicitly—functions are stateless, ephemeral, and scaled by the platform.

## Limitations and Extensions

The original 12 factors focus on application architecture. They don't deeply address:

- **Security**: Authentication, authorization, secrets rotation
- **Telemetry**: Metrics, tracing, health endpoints (beyond logs)
- **API contracts**: Versioning, backwards compatibility
- **Service dependencies**: Circuit breakers, timeouts, retries

Modern "15-factor" and "beyond 12-factor" extensions add:
- **API First**: Design contracts before implementation
- **Telemetry**: Metrics and distributed tracing
- **Authentication/Authorization**: Security as a first-class concern

## Reference Documents

Detailed implementation guidance organized by concern:

- [factors-overview.md](references/factors-overview.md) - Quick reference for all 12 factors
- [code-organization.md](references/code-organization.md) - Codebase, Dependencies (Factors 1-2)
- [configuration.md](references/configuration.md) - Config, Backing Services (Factors 3-4)
- [deployment.md](references/deployment.md) - Build/Release/Run, Processes, Port Binding (Factors 5-7)
- [operations.md](references/operations.md) - Concurrency, Disposability, Dev/Prod Parity (Factors 8-10)
- [observability.md](references/observability.md) - Logs, Admin Processes (Factors 11-12)

## Attribution

**Primary Source:**
- [12factor.net](https://12factor.net/) - Adam Wiggins, Heroku (2011)
- [Heroku Open-Sources 12-Factor Definition](https://blog.heroku.com/twelve-factor-app-definition-open-source) (2024)

**Supporting Resources:**
- Kevin Hoffman, *Beyond the Twelve-Factor App* (O'Reilly, 2016)
- AWS: *Applying the Twelve-Factor App Methodology to Serverless Applications*
- Red Hat: *12-Factor App Meets Kubernetes*
