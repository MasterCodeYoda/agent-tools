# Agent Tools

A canonical, portable skill corpus for modern coding agents (Claude Code, Grok, Factory Droid, etc.).

Clone once, run `./setup.sh`, and get a consistent set of high-quality skills across all your projects and agents. The system automatically publishes the canonical source (`src/`) into agent-specific trees (`dist/<agent>/skills/`) and installs them in the right places (global profile vs local project).

## Quick Start

```bash
git clone <repo-url> ~/Source/agent-tools   # or wherever you keep repos
cd ~/Source/agent-tools
./setup.sh
```

`setup.sh` does the following automatically:

1. Publishes the canonical skills from `src/` into `dist/<agent>/skills/` (resolving any agent-specific markup).
2. Installs the appropriate skills into your environment:
   - Most skills go into your user profile (`~/.claude/skills/`, `~/.grok/skills/`, `~/.factory/skills/`).
   - Project-scoped skills (currently just the `skills` meta-skill) go into the local project directory (`.claude/skills/`, `.grok/skills/`, `.factory/skills/`).

| Target                  | Behavior                                      |
|-------------------------|-----------------------------------------------|
| `~/.claude/skills/`     | Symlinked from `dist/claude/skills/`          |
| `~/.grok/skills/`       | Symlinked from `dist/grok/skills/`            |
| `~/.factory/skills/`    | Copied from `dist/factory/skills/`            |
| `./.claude/skills/` etc.| Local project copy of project-scoped skills   |

Re-run `./setup.sh` after pulling changes. The publisher runs on every invocation.

### Publishing Model

The system is built around a clean separation:

- `src/` — The single source of truth. All skill development happens here. Skills may contain lightweight embedded markup (`<!-- agent:include claude --> ... <!-- /agent:include claude -->`) when behavior must differ between agents.
- `tools/publish-skills.sh` — A thin, mechanical publisher (pure bash + portable awk). It walks `src/`, resolves the markup for each target agent, strips all HTML comments, and writes clean trees to `dist/<agent>/skills/`.
- `setup.sh` — Runs the publisher, then installs the resulting skills into the right locations based on a `publish-target` field in each skill’s frontmatter:
  - `publish-target: user-profile` (default) → installed into your global `~/.claude/skills/`, `~/.grok/skills/`, or `~/.factory/skills/`.
  - `publish-target: project` → installed only into the local project directory (`.claude/skills/`, `.grok/skills/`, `.factory/skills/`). Currently only the `skills` meta-skill uses this.

This design keeps the canonical corpus maintainable while letting each agent receive the cleanest possible version of the skills.

Grok is treated as a first-class target alongside Claude and Factory. Detection for Grok is intentionally a bit more permissive (`~/.grok` or `~/.grok/skills`) because its directory layout is newer.

### Marking Skills as Project-Scoped

Most skills should use the default `publish-target: user-profile`.

Use `publish-target: project` only when a skill is tightly coupled to the agent-tools repository itself (for example, the `skills` meta-skill that provides `/skills:import` and `/skills:evolve`).

Example frontmatter:

```yaml
---
name: skills
description: Meta-skill for importing and evolving the canonical skill corpus.
publish-target: project
---
```

### Inspecting What Would Be Published

You can preview the output of the publishing step without modifying anything:

```bash
tools/publish-skills.sh --dry-run --agents grok
```

For the full markup specification, see [src/skills/references/MARKUP.md](src/skills/references/MARKUP.md).

## What's Included

### Skills — Reusable Knowledge Modules

Skills are context-aware reference material that Claude loads on demand via `@skill-name`.

| Skill | Purpose |
|-------|---------|
| **workflow** | Core philosophy — decomposition modes (vertical-slice + deliverable-partition), session continuity, P1/P2/P3 prioritization, and the workflow command set |
| **clean-architecture** | Language-agnostic Clean Architecture with the Dependency Rule, layer patterns, and per-language guides (Python, TypeScript, C#, Rust) |
| **code-patterns** | Language-specific best practices — type safety, error handling, testing idioms, and framework conventions |
| **test-strategy** | Strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, and AI-specific anti-patterns |
| **audit** | Domain definitions for the unified audit command — code, tests, API, frontend, docs, repo, and QA coverage agents |
| **product** | Product strategy — positioning frameworks, competitive research methodology, messaging principles, and go-to-market patterns |
| **use-browser** | Browser automation via Chrome DevTools MCP and agent-browser CLI |
| **visual-design** | 73 visual design micro-patterns from [detail.design](https://detail.design) — motion, accessibility, typography, and interaction details |
| **qa** | QA workflows — NL spec authoring for Playwright Test Agents and visual inspection tools |

### Commands — Executable Workflows

Commands are invoked with `/command-name` in Claude Code (or Factory.ai).

#### Workflow Commands

| Command | Purpose |
|---------|---------|
| `/workflow:refine` | Discover and refine requirements through guided conversation |
| `/workflow:plan` | Create implementation plans from requirements with approval gates |
| `/workflow:execute` | Session-based work execution with progress tracking |
| `/workflow:review` | Code review for PRs, git ranges, files, or uncommitted changes |
| `/workflow:compound` | Capture knowledge from solved problems + maintain memory quality |
| `/workflow:audit` | Unified project audit — 7 domains (code, tests, API, frontend, docs, repo, QA) with cross-domain deduplication |

#### Product Commands

| Command | Purpose |
|---------|---------|
| `/product:audit` | Research-driven audit of product positioning, messaging, and competitive stance |
| `/product:position` | Guided positioning exercise with competitive research |
| `/product:brief` | Generate product content from positioning research |

#### QA Commands

| Command | Purpose |
|---------|---------|
| `/qa:setup` | Initialize NL spec-driven QA testing with Playwright Test Agents |
| `/qa:discover` | Scan app, import docs, or guided conversation to author NL test specs |
| `/qa:audit` | Detect drift between NL specs, generated tests, and app behavior |

#### Git Commands

| Command | Purpose |
|---------|---------|
| `/git:commit` | Create a well-formed commit |
| `/git:commit-push` | Commit and push |
| `/git:commit-pr` | Commit, push, and open a PR |
| `/git:worktree-create` | Create a git worktree and enter it for immediate work |
| `/git:worktree-delete` | Delete a git worktree with merge safety checks |

## Project Structure

```
agent-tools/
├── src/                             # Canonical source (the truth)
│   ├── workflow/
│   ├── clean-architecture/
│   ├── visual-design/
│   ├── skills/                      # Meta-skill (import + evolve) — deployed to local project only
│   └── ...
├── dist/                            # Generated output (gitignored)
│   ├── claude/skills/
│   ├── grok/skills/
│   └── factory/skills/
├── tools/
│   └── publish-skills.sh            # Thin mechanical publisher (bash + awk)
├── setup.sh                         # Publishes + installs for your agents
└── README.md
```

All development happens under `src/`. `setup.sh` runs the publisher to produce clean per-agent trees under `dist/`.
```

## Design Principles

**Decomposition Modes** — Two top-level modes:
- *Vertical-slice* (default for incremental feature work, especially user-facing): build complete features end-to-end through all layers, not layer by layer.
- *Deliverable-partition* (for foundation, cross-cutting, or large-effort work where vertical slicing risks process-induced slowdown or gaps in requirements / Definition of Done conformance): decompose by deliverable with verbatim parent-AC ownership in each sub-issue, AC traceability matrix in the parent.

See `skills/workflow-guide/SKILL.md` for full mode-selection criteria.

**Bottom-Up Implementation (within a vertical slice)** — Domain first, then Application, Infrastructure, and finally Framework. Pure business logic before I/O. In deliverable-partition mode, plan deliverables in their dependency order instead (e.g., contracts before consumers).

**Session Continuity** — State persists in `./planning/<project>/session-state.md` so work resumes across sessions without losing context.

**Knowledge Compounding** — Solutions are captured and reused. `/workflow:compound` turns solved problems into team knowledge.

**P1/P2/P3 Prioritization** — Every plan, review, and audit uses the same priority framework: P1 (must-have), P2 (should-have), P3 (nice-to-have).

## Attribution

Much of the content here draws from techniques, patterns, and guides shared freely by others in the community. I've adapted and integrated them into a cohesive workflow that fits the way I work. Where a skill is based on or inspired by someone else's work, the corresponding `SKILL.md` includes a reference to the original author.
