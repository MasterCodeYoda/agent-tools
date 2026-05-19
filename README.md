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
| `~/.factory/skills/`    | Copied (rsync --delete) from `dist/factory/skills/` |
| `./.claude/skills/` etc.| Per-skill symlink (Claude/Grok) or copy (Factory) of project-scoped skills only |

Re-run `./setup.sh` after pulling changes. The publisher runs on every invocation.

### Publishing Model

The system is built around a clean separation:

- `src/` — The single source of truth. All skill development happens here. Skills may contain lightweight embedded markup (`<!-- agent:include claude --> ... <!-- /agent:include claude -->`) when behavior must differ between agents.
- `tools/publish-skills.sh` — A thin, mechanical publisher (pure bash + portable awk). It walks `src/`, resolves the `agent:include` / `agent:exclude` markup for each target agent, strips all HTML comments, and writes clean trees to `dist/<agent>/skills/`. For any sub-skill whose `name:` frontmatter contains a colon (e.g. `git:commit`, `workflow:refine`), it also emits a top-level hyphenated sibling (e.g. `git-commit/`, `workflow-refine/`) so that both family overviews (`/git`) and direct sub-commands (`/git-commit`) appear in agent slash menus.
- `setup.sh` — Runs the publisher on every invocation, then installs skills from `dist/<agent>/skills/` into the right locations based on each skill’s `publish-target` frontmatter:
  - `publish-target: user-profile` (default) → installed (symlinked for Claude/Grok, copied for Factory) into your global `~/.claude/skills/`, `~/.grok/skills/`, or `~/.factory/skills/`.
  - `publish-target: project` → installed only into the local project directory (`.claude/skills/`, `.grok/skills/`, `.factory/skills/`). Currently only the `skills` meta-skill group uses this.
  - Every installed skill receives a `.agent-tools` marker file. On subsequent runs, `setup.sh` automatically prunes any previously-managed skills that no longer exist in the current published set (safe cleanup after renames, refactors, or removals without touching third-party skills).

This design keeps the canonical corpus maintainable while letting each agent receive the cleanest possible version of the skills.

Grok is treated as a first-class target alongside Claude and Factory. Detection for Grok is intentionally a bit more permissive (`~/.grok` or `~/.grok/skills`) because its directory layout is newer.

### Marking Skills as Project-Scoped

Most skills should use the default `publish-target: user-profile`.

Use `publish-target: project` only when a skill is tightly coupled to the agent-tools repository itself (for example, the `skills` meta-skill that provides `/skills:import` and `/skills:evolve`).

Example frontmatter (for the project-scoped meta-skill):

```yaml
---
name: skills
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
| **workflow** | Parent for the workflow family — decomposition modes (vertical-slice + deliverable-partition), session continuity, P1/P2/P3 prioritization, knowledge compounding, and commands (`:plan`, `:execute`, `:review`, `:audit`, `:compound`, `:refine`) |
| **git** | Family of safe, conventional git skills — commits, push/PR flows, and worktree-based parallel development (includes both `/git` overview and direct `/git-commit` etc.) |
| **product** | Parent for the product family — positioning frameworks, competitive research, messaging, go-to-market patterns, briefs, and audits |
| **qa** | Parent for the QA family — NL spec authoring for Playwright Test Agents, visual inspection tools, discovery, and coverage auditing |
| **skills** | Meta-skill (project-scoped only) for importing skills from other agents and iteratively evolving the canonical corpus |
| **clean-architecture** | Language-agnostic Clean Architecture with the Dependency Rule, layer patterns, and per-language guides (Python, TypeScript, C#, Rust) |
| **code-patterns** | Language-specific best practices — type safety, error handling, testing idioms, and framework conventions |
| **test-strategy** | Strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, SCRAP quality scoring, and AI-specific anti-patterns |
| **use-browser** | Browser automation via Chrome DevTools MCP and agent-browser CLI |
| **visual-design** | 73 visual design micro-patterns from [detail.design](https://detail.design) — motion, accessibility, typography, and interaction details |

### Commands — Executable Workflows

Commands are invoked with `/command-name` (or the hyphenated equivalents produced by the publisher for sub-commands) in supported agents. Each family also provides an invocable overview skill (e.g. `/workflow`, `/git`) that surfaces the full command table and guidance.

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
├── src/                             # Canonical source of truth (agent-agnostic + embedded markup)
│   ├── workflow/                    # + planning/, execution/, audit/, review/, compound/, refine/, references/
│   ├── git/                         # + commit/, worktree-create/, ... (family overview + subs)
│   ├── product/                     # + position/, brief/, audit/
│   ├── qa/                          # + setup/, discover/, tools/, templates/, references/
│   ├── skills/                      # Meta-skill (import + evolve) — publish-target: project
│   ├── clean-architecture/
│   ├── code-patterns/
│   ├── test-strategy/
│   ├── use-browser/
│   ├── visual-design/
│   └── ...
├── dist/                            # Generated per-agent trees (gitignored)
│   ├── claude/skills/               # includes family/ + flattened command/ (e.g. git-commit/)
│   ├── grok/skills/
│   └── factory/skills/
├── tools/
│   └── publish-skills.sh            # Mechanical publisher (bash + awk): markup resolution + flattening
├── setup.sh                         # Runs publisher + installs (user profile vs project) + prunes stale
└── README.md
```

All development happens under `src/`. `setup.sh` runs the publisher to produce clean per-agent trees under `dist/`.
```

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

Much of the content here draws from techniques, patterns, and guides shared freely by others in the community. I've adapted and integrated them into a cohesive workflow that fits the way I work. Where a skill is based on or inspired by someone else's work, the corresponding `SKILL.md` includes a reference to the original author.
