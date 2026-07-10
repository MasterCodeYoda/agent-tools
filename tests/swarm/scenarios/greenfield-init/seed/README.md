# greeter (scenario seed)

A tiny greeting CLI for the `greenfield-init` swarm scenario. Commands auto-discover from
`greeter/commands/` (each module exposes `NAME` + `run(argv)`), so independent commands are
added as separate files and never collide at merge.

This scenario ships **no charter** — the run begins with `/swarm:setup`, which detects the
stack (Python + pytest from `pyproject.toml`), authors the charter, and bootstraps the
`.agent-tools/` umbrella. The backlog is then a simple two-item parallel pass — the point is
exercising `/swarm:setup` and a clean orchestrator run, not the conflict/integration paths
(those live in `cli-task-manager`).
