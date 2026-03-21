# Agent Tools

Shared skills and commands for Claude Code (and Factory.ai) that bring consistent, opinionated workflows to every project. Clone once, symlink everywhere — every repo gets the same architecture guidance, workflow commands, and language patterns without copy-pasting.

## Quick Start

```bash
git clone <repo-url> ~/Source/agent-tools   # or wherever you keep repos
cd ~/Source/agent-tools
./setup.sh
```

`setup.sh` creates symlinks so your tools can find these files:

| Target | Skills | Commands |
|--------|--------|----------|
| `~/.claude/` | `skills/` | `commands/` (nested) |
| `~/.factory/` | `skills/` | `factory-commands/` (flattened, because Factory.ai doesn't support folder namespacing) |

Re-run `setup.sh` after pulling new changes — it's idempotent.

## What's Included

### Skills — Reusable Knowledge Modules

Skills are context-aware reference material that Claude loads on demand via `@skill-name`.

| Skill | Purpose |
|-------|---------|
| **workflow-guide** | Core philosophy — vertical slicing, session continuity, P1/P2/P3 prioritization, and the workflow command set |
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
├── skills/                          # Reusable knowledge modules (@skill-name)
│   ├── workflow-guide/              # Core workflow philosophy + planning templates
│   ├── clean-architecture/          # CA principles, language guides, examples
│   ├── code-patterns/               # Language-specific patterns (Python, TS, C#, Rust)
│   ├── test-strategy/               # Strategy selection + reference material
│   ├── audit/                       # Domain definitions for unified /workflow:audit
│   ├── product/                     # Product strategy + positioning frameworks
│   ├── use-browser/                 # Browser automation (Chrome DevTools MCP + agent-browser)
│   ├── visual-design/              # 73 visual design micro-patterns (detail.design)
│   └── qa/                          # QA workflows — NL spec authoring + visual inspection tools
├── commands/                        # Executable workflows (/command-name)
│   ├── workflow/                    # 6 workflow commands (refine, plan, execute, review, compound, audit)
│   ├── product/                     # 3 product commands (audit, position, brief)
│   ├── qa/                          # 3 QA commands (setup, discover, audit)
│   └── git/                         # 5 git commands
├── tests/scenarios/                 # Synthetic test scenarios for /evolve effectiveness validation
├── factory-commands/                # Auto-generated flattened commands for Factory.ai
├── setup.sh                         # Symlink installer
└── README.md
```

## Design Principles

**Vertical Slicing** — Build complete features end-to-end, not layer by layer. Every plan breaks work into thin, deliverable slices.

**Bottom-Up Implementation** — Domain first, then Application, Infrastructure, and finally Framework. Pure business logic before I/O.

**Session Continuity** — State persists in `./planning/<project>/session-state.md` so work resumes across sessions without losing context.

**Knowledge Compounding** — Solutions are captured and reused. `/workflow:compound` turns solved problems into team knowledge.

**P1/P2/P3 Prioritization** — Every plan, review, and audit uses the same priority framework: P1 (must-have), P2 (should-have), P3 (nice-to-have).

## Attribution

Much of the content here draws from techniques, patterns, and guides shared freely by others in the community. I've adapted and integrated them into a cohesive workflow that fits the way I work. Where a skill is based on or inspired by someone else's work, the corresponding `SKILL.md` includes a reference to the original author.
