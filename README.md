# Agent Tools

A canonical, portable skill corpus for modern coding agents (Claude Code, Codex, Grok, Factory Droid, OpenCode).

**The problem this solves:** every coding agent wants its own skills directory, its own
discovery quirks, and its own dialect — so the knowledge you invest in one agent doesn't
travel, and copies drift apart. Agent Tools keeps one canonical source of truth with
lightweight per-agent markup, mechanically publishes clean per-agent trees, and installs
them where each agent looks. Write a skill once; every agent gets its best version.

Clone once, run `./setup.sh`, and get a consistent set of high-quality skills across all your projects and agents. The system automatically publishes the canonical source (`src/`) into agent-specific trees (`dist/<agent>/skills/`) and installs them in the right places (global profile vs local project).

New here? Start with the worked walkthrough in [docs/getting-started.md](docs/getting-started.md).

## Quick Start

```bash
git clone <repo-url> ~/Source/agent-tools   # or wherever you keep repos
cd ~/Source/agent-tools
./setup.sh
```

`setup.sh` does the following automatically:

1. Publishes the canonical skills from `src/` into `dist/<agent>/skills/` (resolving any agent-specific markup) for all five targets: claude, grok, factory, codex, opencode.
2. Installs the appropriate skills into your environment:
   - Most skills go into your user profile (`~/.claude/skills/`, `~/.grok/skills/`, `~/.factory/skills/`, `~/.codex/skills/`, `~/.config/opencode/skills/`).
   - Project-scoped skills (the `skills` meta-skill and `swarm-test`) go into the local project directory (`.claude/skills/`, `.grok/skills/`, `.factory/skills/`, `.codex/skills/`, `.opencode/skills/`).

| Target                      | Behavior                                      |
|-----------------------------|-----------------------------------------------|
| `~/.claude/skills/`         | Symlinked from `dist/claude/skills/`          |
| `~/.grok/skills/`           | Symlinked from `dist/grok/skills/`            |
| `~/.factory/skills/`        | Symlinked from `dist/factory/skills/`         |
| `~/.codex/skills/`          | Symlinked from `dist/codex/skills/`           |
| `~/.config/opencode/`       | Symlinked skills from `dist/opencode/skills/` + native commands from `dist/opencode/commands/` (XDG layout) |
| `./.claude/skills/` etc.    | Per-skill symlink (all agents) of project-scoped skills only |

Re-run `./setup.sh` after pulling changes. The publisher runs on every invocation.

### Publishing Model

The system is built around a clean separation:

- `src/` — The single source of truth. All skill development happens here. Skills may contain lightweight embedded markup (`<!-- agent:include claude --> ... <!-- /agent:include claude -->`) when behavior must differ between agents.
- `tools/publish-skills.sh` — A thin, mechanical publisher (pure bash + portable awk). It walks `src/`, resolves the `agent:include` / `agent:exclude` markup for each target agent, strips HTML comments outside fenced code (fenced examples and backticked comment literals publish verbatim), and writes clean trees to `dist/<agent>/skills/`. For agents whose skill discovery only sees direct children of the skills directory (Claude, Grok, Factory) it also emits top-level hyphenated siblings (e.g. `git-commit/`) for any sub-skill whose `name:` frontmatter contains a colon, so both family overviews and direct sub-commands appear in slash menus. Codex receives only the hierarchical tree (it recursively discovers nested SKILL.md files). (Grok's loader does not yet promote invocable sub-skills as first-class top-level commands, so these siblings are currently inert there — but they are published for it so they "just work" the moment that limitation is fixed upstream.)
- `setup.sh` — Runs the publisher on every invocation, then installs skills from `dist/<agent>/skills/` into the right locations based on each skill’s `publish-target` frontmatter:
  - `publish-target: user-profile` (default) → installed (symlinked) into your global `~/.claude/skills/`, `~/.grok/skills/`, `~/.factory/skills/`, `~/.codex/skills/`, or `~/.config/opencode/skills/`.
  - `publish-target: project` → installed only into the local project directory (`.claude/skills/`, `.grok/skills/`, `.factory/skills/`, `.codex/skills/`, `.opencode/skills/`). Currently used by the `skills` meta-skill and `swarm-test`.
  - Every installed skill receives a `.agent-tools` marker file. On subsequent runs, `setup.sh` automatically prunes any previously-managed skills that no longer exist in the current published set (safe cleanup after renames, refactors, or removals without touching third-party skills).

This design keeps the canonical corpus maintainable while letting each agent receive the cleanest possible version of the skills.

Grok is treated as a first-class target alongside Claude and Factory. Detection for Grok is intentionally a bit more permissive (`~/.grok` or `~/.grok/skills`) because its directory layout is newer. The publisher emits the flattened command siblings for Grok too; until Grok's loader promotes invocable sub-skills as top-level commands, the family overview skills remain the practical surface (and document the sub-commands), but the flattened entries are already in place for when that lands.

### Marking Skills as Project-Scoped

Most skills should use the default `publish-target: user-profile`.

Use `publish-target: project` only when a skill is tightly coupled to the agent-tools repository itself (for example, the `skills` meta-skill **and** its invocable leaves `/skills:import` and `/skills:evolve`). Flattened leaves (`skills-evolve/`, `skills-import/`) must declare project scope on their own `SKILL.md` as well — install does not treat “parent is project” as optional. OpenCode also loads `~/.claude/skills/`, so a leaf left on the default `user-profile` target leaks into every project’s autocomplete.

Example frontmatter (for the project-scoped meta-skill and each leaf):

```yaml
---
name: skills          # or skills:evolve / skills:import
description: Meta-skill for importing and evolving the canonical skill corpus.
publish-target: project
user-invocable: true
---
```

Most skills (especially family overviews and command leaves) also declare `user-invocable: true` so they appear in agent slash/autocomplete menus. The publisher preserves this field.

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
| **workflow** | Parent for the workflow family — bare `/workflow` is portfolio status (read-only); `/workflow:continue` drives work; decomposition modes, session continuity, knowledge compounding; phase commands (`:setup`, `:prune`, `:roadmap`, `:brainstorm`, `:refine`, `:plan`, `:execute`, `:review`, `:audit`, `:compound`) |
| **swarm** | Parallel multi-item orchestration on top of `/workflow` — usually entered via continue when roadmap has explicit `∥` waves; bare `/swarm` is status; `/swarm <goal>` override; `/swarm:setup` charter + umbrella; `/swarm:continue` resumes a paused run |
| **git** | Family of safe, conventional git skills — commits, push/PR flows, and worktree-based parallel development (includes `/git` overview + sub-commands reachable via the parent or exact name) |
| **product** | Parent for the product family — positioning frameworks, competitive research, messaging, go-to-market patterns, briefs, and audits |
| **qa** | Parent for the QA family — NL spec authoring for Playwright Test Agents, visual inspection tools, discovery; drift detection via `/workflow:audit` |
| **skills** | Meta-skill (project-scoped only) for importing skills from other agents and iteratively evolving the canonical corpus |
| **personify** | Project-specific agent personality, voice guidance, and communication facts stored in bounded `.agent-tools/personify.md` (token limits + proactive maintenance). Invocable as `/personify` for interactive management |
| **swarm-test** | (project-scoped) Drives and analyzes `/swarm` test-harness runs (repo-development tool) |
| **clean-architecture** | Language-agnostic Clean Architecture with the Dependency Rule, layer patterns, and per-language guides (Python, TypeScript, C#, Rust) |
| **code-patterns** | Language-specific best practices — type safety, error handling, testing idioms, and framework conventions |
| **test-strategy** | Strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, SCRAP quality scoring, and AI-specific anti-patterns |
| **use-browser** | Browser automation via Chrome DevTools MCP and agent-browser CLI |
| **visual-design** | 73 visual design micro-patterns from [detail.design](https://detail.design) — motion, accessibility, typography, and interaction details |

### Commands — Executable Workflows

Commands are invoked with `/command-name` (or the hyphenated equivalents for sub-commands) in supported agents. For Claude and Factory both the family overview and direct sub-commands appear in slash menus (via the emitted flat siblings). The same flattened siblings are published for Grok, but until its loader promotes invocable sub-skills the family overview skills (`/git`, `/workflow`, etc.) remain the practical surface — they document the available sub-commands, which remain reachable by exact name. Codex discovers the nested layout directly and uses the `name:` declared in each SKILL.md (no hyphenated siblings are created for it). Each family also provides an invocable overview skill that surfaces the full command table and guidance.

#### Workflow Commands

| Command | Purpose |
|---------|---------|
| `/workflow` | **Status** — read-only portfolio glance (planning root, in-progress/NEXT, soft signals, continue-mode preview); focused status with a unit arg |
| `/workflow:continue` | **Drive** — orient from `planning/`, portfolio mode (swarm resume/handoff on explicit `∥` waves, or unit phase state machine); never invents NEXT |
| `/workflow:setup` | Initialize/maintain `planning/` docs and define project-local conventions (tracks, gates, policy) |
| `/workflow:prune` | Sweep `planning/` for completed work, verify against git + PM, and purge on approval |
| `/workflow:brainstorm` | Explore a fuzzy idea into a framed concept ready for refinement |
| `/workflow:refine` | Discover and refine requirements through guided conversation |
| `/workflow:plan` | Create implementation plans from requirements with approval gates |
| `/workflow:execute` | Session-based work execution with progress tracking |
| `/workflow:review` | Code review for PRs, git ranges, files, or uncommitted changes |
| `/workflow:audit` | Unified project audit — 7 domains (code, tests, API, frontend, docs, repo, QA) with cross-domain deduplication |
| `/workflow:compound` | Capture knowledge from solved problems + maintain memory quality |

#### Swarm Commands

| Command | Purpose |
|---------|---------|
| `/swarm` | Summarize a project's swarm state (active run, item stages, or whether it's initialized) |
| `/swarm <goal>` | Override entry for parallel orchestration on a goal (also auto-entered from `/workflow:continue` when roadmap has an explicit `∥` / `{wave}` at the head). Classifies items, drives refine (host) → plan → implement → review → local-merge via role-specialized sub-agents in parallel waves |
| `/swarm:setup` | Author the project charter and set up the `.agent-tools/` umbrella (idempotent, evidence-grounded) |
| `/swarm:continue` | Resume the most recent paused run, reconciling saved state against disk + PM ground truth |

> The orchestrator runs in your session (no tmux/daemon), **never pushes to remote**, and
> merges to `main` locally with the full test suite between merges. Per-item work is isolated
> in git worktrees and each worker runs an ordinary `/workflow` command. Cross-CLI worker
> dispatch is a later phase.

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

Drift detection between specs, generated tests, and app behavior is available via `/workflow:audit` (qa domain). A dedicated `/qa:audit` leaf is planned but not yet implemented as a standalone command.

#### Personify Commands

| Command | Purpose |
|---------|---------|
| `/personify` | Initialize or review/edit + maintain (with token limits and cleanup guidance) the project agent personality/voice profile (interactive) |

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
├── src/                             # Canonical source of truth (agent-agnostic + embedded markup)
│   ├── workflow/                    # + setup/, prune/, brainstorm/, planning/, execution/, review/, audit/, compound/, continue/, references/
│   ├── git/                         # + commit/, worktree-create/, ... (family overview + subs)
│   ├── product/                     # + position/, brief/, audit/
│   ├── qa/                          # + setup/, discover/, tools/, templates/, references/
│   ├── skills/                      # Meta-skill (import + evolve) — publish-target: project
│   ├── personify/                   # Agent personality, voice, and comms facts skill
│   ├── clean-architecture/
│   ├── code-patterns/
│   ├── test-strategy/
│   ├── use-browser/
│   ├── visual-design/
│   └── ...
├── dist/                            # Generated per-agent trees (gitignored)
│   ├── claude/skills/               # family/ + flattened command siblings (e.g. git-commit/)
│   ├── grok/skills/                 # family/ + flattened command siblings (inert until Grok's loader supports them)
│   ├── factory/skills/              # family/ + flattened command siblings
│   └── codex/skills/                # family/ + nested sub-skills only (Codex recurses for discovery)
├── tools/
│   └── publish-skills.sh            # Mechanical publisher (bash + awk): markup resolution + agent-specific flattening (Claude/Grok/Factory only)
├── setup.sh                         # Runs publisher + installs (user profile vs project) + prunes stale
└── README.md
```

All development happens under `src/`. `setup.sh` runs the publisher to produce clean per-agent trees under `dist/`.
```

### The `.agent-tools/` Umbrella (in target projects)

The structure above is the **agent-tools repo itself**. Separately, when you run `/swarm:setup`
in one of *your* projects, it creates a small `.agent-tools/` umbrella there to hold
agent-tools meta-artifacts:

```
<your-project>/
├── .agent-tools/
│   ├── charter/
│   │   ├── charter.md          # entry + precedence + file index
│   │   ├── project.md          # what the project is
│   │   ├── engineering.md      # how we build
│   │   └── workflow.md         # how we move
│   ├── personify.md            # agent personality, voice guidance, interpersonal facts (single bounded file with token limits)
│   ├── swarm/
│   │   ├── config.yml          # orchestrator preferences (committed)
│   │   ├── roles/              # role templates, editable per project (committed)
│   │   ├── active-run          # pointer to the current run (gitignored)
│   │   └── sessions/<run-id>/  # per-run state.yml + logs (gitignored)
│   └── .gitignore              # umbrella gitignore (add-don't-remove)
├── AGENTS.md                   # charter-link block (CLAUDE.md/GEMINI.md may symlink to it)
└── planning/                   # stays at the project root (intentional carve-out)
```

The umbrella primarily covers **charter + swarm + other durable agent configuration** (e.g. personify). `./planning/` is an explicit carve-out for transient work artifacts — it stays at the project root for high-traffic daily use. It uses directory-local `.gitkeep` and `.gitignore` rules (top-level and per-item: ignore everything except `.gitkeep` and `conventions.md` at top level). `/workflow:setup` enforces this structure idempotently. Workflow may reference `.agent-tools/` for durable items.

## Design Principles

**Decomposition Modes** — Two top-level modes:
- *Vertical-slice* (default for incremental feature work, especially user-facing): build complete features end-to-end through all layers, not layer by layer.
- *Deliverable-partition* (for foundation, cross-cutting, or large-effort work where vertical slicing risks process-induced slowdown or gaps in requirements / Definition of Done conformance): decompose by deliverable with verbatim parent-AC ownership in each sub-issue, AC traceability matrix in the parent.

See `src/workflow/SKILL.md` for full mode-selection criteria.

**Bottom-Up Implementation (within a vertical slice)** — Domain first, then Application, Infrastructure, and finally Framework. Pure business logic before I/O. In deliverable-partition mode, plan deliverables in their dependency order instead (e.g., contracts before consumers).

**Session Continuity** — State persists in `./planning/<project>/session-state.md` so work resumes across sessions without losing context.

**Knowledge Compounding** — Solutions are captured and reused. `/workflow:compound` turns solved problems into team knowledge.

**P1/P2/P3 Prioritization** — Every plan, review, and audit uses the same priority framework: P1 (must-have), P2 (should-have), P3 (nice-to-have).

## Attribution

Much of the content here draws from techniques, patterns, and guides shared freely by others in the community. I've adapted and integrated them into a cohesive workflow that fits the way I work. Where a skill is based on or inspired by identifiable work, the corresponding `SKILL.md` (or its references) credits the original author. The remainder is original synthesis of widely-shared community practice.

## License

[MIT](LICENSE).
