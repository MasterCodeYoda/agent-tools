# Authoring Adapter Contract

Sentinel has two separate layers:

| Layer | Owns | Examples |
|-------|------|----------|
| Harness | Deterministic test execution and durable coverage intent | `sentinel.config.yaml`, `specs/`, generated/curated Playwright tests, `seed.spec.ts`, `playwright.config.ts` |
| Authoring adapters | Client-specific agent plumbing for planning, generating, and healing tests | `.mcp.json`, `.claude/agents/`, `opencode.json`, `.opencode/prompts/` |

## Source Of Truth

`sentinel.config.yaml` is the only place project-specific Sentinel facts belong:

- app name and base URL
- auth strategy, login path, test username, and password env var name
- Playwright config path
- NL spec directory
- generated/curated test directory
- seed fixture path
- selected authoring adapter providers
- bridge/shim/partition details, when applicable

Adapter prompt files must not duplicate those facts. They should tell the agent to read `sentinel.config.yaml` before doing work.

## Generated Files

Treat authoring adapter files as generated boilerplate owned by `/qa:setup`:

- Do not hand-customize planner/generator/healer prompts with project facts.
- Do not put real credentials or app-specific secrets in adapter files.
- If project paths, auth strategy, or providers change, update `sentinel.config.yaml` and rerun `/qa:setup` or the adapter regeneration step.
- It is acceptable for MCP/client config files to contain mechanically generated command paths, such as a `--config` argument, because those files are read before the agent can inspect YAML.

## Adapter Prompt Rule

Every planner, generator, and healer prompt should contain this project-agnostic instruction, or an equivalent:

```text
Before starting, read sentinel.config.yaml and use its app, auth, playwright, specs, and authoring_adapters sections as the source of truth. This adapter file is generated boilerplate; do not encode project-specific paths, credentials, URLs, or behavior here.
```

## Execution Independence

CI and local deterministic execution must not depend on an authoring adapter. The test suite should run through Playwright directly, for example:

```bash
npx playwright test
```

Authoring adapters are useful for creating and maintaining tests. They are not part of the runtime test contract.
