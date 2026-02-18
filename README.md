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
| **workflow-guide** | Core philosophy — vertical slicing, session continuity, P1/P2/P3 prioritization, and the 10-command workflow |
| **clean-architecture** | Language-agnostic Clean Architecture with the Dependency Rule, layer patterns, and per-language guides (Python, TypeScript, C#, Rust) |
| **code-patterns** | Language-specific best practices — type safety, error handling, testing idioms, and framework conventions |
| **test-strategy** | Strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, and AI-specific anti-patterns |
| **logging** | Structured logging standards — required fields, context propagation, and level guidelines |
| **12-factor-apps** | Twelve-Factor methodology for building deployment-ready services |
| **use-browser** | Browser automation patterns using the agent-browser CLI |

### Commands — Executable Workflows

Commands are invoked with `/command-name` in Claude Code (or Factory.ai).

#### Workflow Commands

| Command | Purpose |
|---------|---------|
| `/workflow:refine` | Discover and refine requirements through guided conversation |
| `/workflow:plan` | Create implementation plans from requirements with approval gates |
| `/workflow:execute` | Session-based work execution with progress tracking |
| `/workflow:review` | Code review for PRs, git ranges, files, or uncommitted changes |
| `/workflow:compound` | Capture knowledge from solved problems to compound effectiveness |
| `/workflow:audit-tests` | Audit test suite quality, anti-patterns, and coverage gaps |
| `/workflow:audit-code` | Audit production code against code-patterns, clean-architecture, and logging standards |
| `/workflow:audit-docs` | Audit documentation for presence, accuracy, and completeness |
| `/workflow:audit-api` | Audit API surface — REST conventions, schema quality, security |
| `/workflow:audit-frontend` | Audit frontend code — accessibility, components, performance, state |
| `/workflow:audit-repo` | Audit repository readiness for autonomous AI agent coding — CI/CD, review automation, security |

#### Git Commands

| Command | Purpose |
|---------|---------|
| `/git:commit` | Create a well-formed commit |
| `/git:commit-push` | Commit and push |
| `/git:commit-pr` | Commit, push, and open a PR |

## Project Structure

```
agent-tools/
├── skills/                          # Reusable knowledge modules (@skill-name)
│   ├── workflow-guide/              # Core workflow philosophy + planning templates
│   ├── clean-architecture/          # CA principles, language guides, examples
│   ├── code-patterns/               # Language-specific patterns (Python, TS, C#, Rust)
│   ├── test-strategy/               # Strategy selection + reference material
│   ├── logging/                     # Structured logging standards
│   ├── 12-factor-apps/              # Twelve-Factor methodology
│   └── use-browser/                 # Browser automation
├── commands/                        # Executable workflows (/command-name)
│   ├── workflow/                    # 10 workflow commands
│   └── git/                         # 3 git commands
├── factory-commands/                # Auto-generated flattened commands for Factory.ai
├── setup.sh                         # Symlink installer
└── README.md
```

## Design Principles

**Vertical Slicing** — Build complete features end-to-end, not layer by layer. Every plan breaks work into thin, deliverable slices.

**Bottom-Up Implementation** — Domain first, then Infrastructure, Application, and finally Framework. Pure business logic before I/O.

**Session Continuity** — State persists in `./planning/<project>/session-state.md` so work resumes across sessions without losing context.

**Knowledge Compounding** — Solutions are captured and reused. `/workflow:compound` turns solved problems into team knowledge.

**P1/P2/P3 Prioritization** — Every plan, review, and audit uses the same priority framework: P1 (must-have), P2 (should-have), P3 (nice-to-have).

## Attribution

Much of the content here draws from techniques, patterns, and guides shared freely by others in the community. I've adapted and integrated them into a cohesive workflow that fits the way I work. Where a skill is based on or inspired by someone else's work, the corresponding `SKILL.md` includes a reference to the original author.
