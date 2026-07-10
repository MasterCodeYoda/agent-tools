# Template: Sentinel `README.md` content spec

The 12 sections the generated Sentinel `README.md` must cover. Used by
`qa:setup` Phase 8.

1. **Quick Start** — Commands to start infrastructure, run tests, view reports, stop infrastructure
2. **How It Works** — Brief diagram: Playwright → Vite → bridge shim → HTTP bridge → SQLite
3. **Test Partitions** — Table of partition names, bridge ports, test file globs, and workspace paths (if bridge partitions were configured in Phase 3e)
4. **Directory Structure** — Tree showing `specs/`, `tests/`, `seed.spec.ts`, config files
5. **Test Fixtures** — Describe each fixture from `seed.spec.ts` with a usage example
6. **Running Specific Tests** — Commands for single file, single test, single partition, headed, debug
7. **Test Statuses** — Explain `test(...)`, `test.fixme(...)`, `test.skip(...)`, `test.describe.serial(...)`
8. **NL Spec Format** — Brief description with a frontmatter example, point to `specs/` for full examples
9. **Authoring Adapters** — Explain that `.claude/`, `.opencode/`, `.mcp.json`, and similar files are generated boilerplate from `/qa:setup`; project facts live in `sentinel.config.yaml`; rerun setup to regenerate adapters.
10. **Common Workflows** — Adding a new test, investigating a failure, converting a fixme
11. **Troubleshooting** — Common issues: overlay blocking, infrastructure port conflicts, stale bridge state
12. **Sentinel Skills** — Table of `/qa:setup`, `/qa:discover` (drift via `/workflow:audit`)
