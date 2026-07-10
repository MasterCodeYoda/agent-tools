# Getting started

A worked walkthrough from `git clone` to your first structured feature. Fifteen minutes,
one toy project, and you'll have seen the core loop that everything else builds on.

## 1. Install the corpus

```bash
git clone https://github.com/MasterCodeYoda/agent-tools.git ~/Source/agent-tools
cd ~/Source/agent-tools
./setup.sh
```

`setup.sh` publishes the canonical skills for all five supported agents (Claude Code,
Codex, Grok, Factory, OpenCode) and symlinks them into the skills directory of each agent
it detects on your machine. Re-run it any time after pulling changes — it's idempotent and
prunes any skills it previously installed that no longer exist. (OpenCode command symlinks
are not yet pruned automatically.)

Open your agent and type `/` — you should see families like `/workflow`, `/git`, `/qa`
in the slash menu.

## 2. What you just installed

Two kinds of skills:

- **Knowledge skills** load on demand when relevant — `clean-architecture`,
  `code-patterns`, `test-strategy`, `visual-design`, `use-browser`. You don't invoke
  these; the agent pulls them in when the work calls for them.
- **Process skills** are commands you invoke — the `workflow` family is the core loop,
  `git` for commits/PRs/worktrees, `qa` for NL-spec testing, `product` for positioning
  work.

## 3. The core loop, on a toy project

Say you have a small CLI project and want to add a `--json` output flag. In your
project directory, in your agent:

**Refine** — turn the idea into concrete requirements:

```
/workflow:refine add a --json flag that emits machine-readable output
```

The skill interviews you briefly (what's in scope, what's not, acceptance criteria) and
writes `planning/<project>/requirements.md` (with a PM tool configured, it updates the
issue instead). Refine prints the path it saved — use that path in the next two commands.
`planning/` is transient working state — gitignored by convention, living alongside your code.

**Plan** — turn requirements into an implementation plan:

```
/workflow:plan ./planning/add-json-flag/
```

You get a task breakdown, technical decisions, and a testing strategy — and a hard
approval gate: nothing is saved or executed until you approve.

**Execute** — do the work with session tracking:

```
/workflow:execute ./planning/add-json-flag/
```

The agent works the plan task-by-task, runs tests as it goes, updates
`session-state.md` so a future session (or a different agent) can resume exactly where
this one stopped, and commits per completed slice.

**Review and finish**:

```
/workflow:review main..HEAD
```

Multi-lens review with P1/P2/P3 findings. Fix what's real, then merge. Afterwards,
`/workflow:compound` captures anything you learned into project memory so the next
piece of work starts smarter.

**Or let the loop drive itself**: `/workflow:continue` orients from `planning/`, picks
the next slice, and runs refine → plan → execute → review end-to-end, stopping only
where your input is genuinely required (plan approval, review triage, merge).

## 4. Where to go next

- **Scale up**: `/swarm <goal>` drives a whole backlog through the same loop with
  role-specialized sub-agents in parallel worktrees, merging locally with test gates.
  Run `/swarm:setup` once per project first.
- **Teach it your project**: `/workflow:setup` records project-local conventions
  (tracks, gates, merge policy) that every later command honors.
- **Test with natural-language specs**: `/qa:setup` wires Playwright Test Agents;
  `/qa:discover` authors specs by scanning your app.
- **Give the agent a voice**: `/personify` maintains a small, bounded persona file.

The full command tables live in the [README](../README.md). The publishing model —
how one canonical source serves five agents — is documented there too, with the markup
spec at `src/skills/references/MARKUP.md`.
