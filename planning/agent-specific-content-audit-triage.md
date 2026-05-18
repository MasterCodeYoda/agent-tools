# Agent-Specific Content Audit — Full Triage Pass

**Date**: 2026-05-18  
**Status**: Systematic triage pass complete (initial findings)  
**Next Phase**: Selective deep-dive by impact/priority

---

## Inventory

Top-level skills under `src/`:

- clean-architecture
- code-patterns
- git (sub-skills)
- product (sub-skills)
- qa (sub-skills)
- skills (meta-skill: import + evolve)
- test-strategy
- use-browser
- visual-design
- workflow (sub-skills + references)

---

## High-Priority Findings (Require Markup or Major Adaptation)

### 1. Memory Primitives (workflow/references/memory-primitives.md)

- **Signal Strength**: Critical
- **Nature**: Extremely Claude-specific. Entire document is written from the perspective of Claude Code's memory system (`CLAUDE.md` scopes, `~/.claude/projects/`, `claude project purge`, path-scoped `.claude/rules/`, auto-memory, hooks, etc.).
- **Recommendation**: Heavy `<!-- agent:include claude -->` usage or separate Claude-only sections. Consider extracting generalized "memory strategy" concepts.

### 2. Conversation Analysis (workflow/references/conversation-analysis.md)

- **Signal Strength**: High
- **Nature**: Built entirely around Claude Code telemetry files and databases.
- **Recommendation**: Strong candidate for `include claude` blocks. Other agents will need different data sources.

### 3. Playwright Agent Initialization (qa/setup/SKILL.md)

- **Signal Strength**: High
- **Nature**: Hard-coded `npx playwright init-agents --loop=claude`.
- **Recommendation**: Needs markup or alternate path for non-Claude agents.

### 4. Parallel Worktree Execution (workflow/SKILL.md + git/worktree-*)

- **Signal Strength**: Medium-High
- **Nature**: Hard-coded `.claude/worktrees/` paths, detailed Claude-specific worktree exit prompt instructions ("always choose keep"), cleanup commands tied to Claude's implementation.
- **Recommendation**: General worktree concept is portable; concrete paths, prompts, and Claude-specific tooling need markup.

---

## Medium-Priority Findings

### 5. Use-Browser (use-browser/SKILL.md)

- **Signal Strength**: Medium
- **Nature**: Strong preference and detailed decision table for Chrome DevTools MCP vs agent-browser CLI. Some verification language.
- **Recommendation**: Review tool selection guidance for portability. MCP patterns may need light markup for other environments.

### 6. QA Pipeline Description (qa/SKILL.md)

- **Signal Strength**: Medium
- **Nature**: Pipeline diagram and text explicitly name "Claude" as the author of NL specs and auditor.
- **Recommendation**: Consider generalizing the description or marking the current integration as Claude-oriented with notes for future agents.

### 7. Git Worktree Commands (git/worktree-create/SKILL.md, etc.)

- **Signal Strength**: Medium
- **Nature**: Hard-coded `.claude/worktrees/<name>` paths and assumptions about Claude's worktree management.
- **Status**: First pass complete. Claude-specific details wrapped + TODOs added in git sub-skills. Cross-references in workflow sub-documents cleaned to point to git layer (no agent blocks around skill references).

---

## Low-Priority / Minor Findings

- **Visual Design**: One isolated reference to "Claude Code's approach" for AI action verbs — generalized slightly ("one common approach, seen in Claude Code").
- **Clean Architecture**: Minor reference to `.claude/skills/` in validator paths — added clarifying note that the path depends on installation.

**Status**: Both items reviewed and lightly adjusted for the triage pass.
- **Test Strategy**: AI-specific anti-patterns are well-written and mostly agent-agnostic.
- **Product**: Research-first methodology and frameworks appear portable.
- **Code Patterns**: Language-specific, not agent-specific.

---

## Skills with Low Apparent Agent Specificity

- clean-architecture (core)
- code-patterns
- product (main + subs)
- test-strategy
- skills meta-skill (already correctly marked `publish-target: project`)

---

## Summary Classification

| Category | Count | Examples |
|----------|-------|----------|
| Critical / High (needs significant markup) | 4 | memory-primitives, conversation-analysis, qa setup init-agents, worktree parallel execution |
| Medium | 3 | use-browser, qa pipeline, git worktree commands |
| Low / Trivial | 2+ | visual-design, clean-architecture validator paths |
| Low Specificity | 5+ | clean-architecture, code-patterns, product, test-strategy, skills meta |

---

## Recommended Deep-Dive Order (by Impact)

1. **Memory Primitives** (workflow/references/memory-primitives.md) — Largest single source of Claude lock-in.
2. **Conversation Analysis** (workflow/references/conversation-analysis.md)
3. **Playwright Agent Init** (qa/setup/SKILL.md) — Concrete, mechanical change.
4. **Worktree Handling** (workflow + git/worktree-*) — Affects parallel execution, a major feature.
5. **Use-Browser** — High-usage skill.
6. **QA Pipeline Description** — Messaging vs implementation.

---

**Progress**:
- Memory Primitives: **Final polish pass complete**. Grok and Factory sections now have high-quality, researched content. Document follows the desired per-section structure and is ready for publication.
- Conversation Analysis: First structural pass complete.
- Playwright Agent Init (`qa/setup/SKILL.md`): First pass complete.
- Worktree Handling: First pass complete.
- Use-Browser: Reviewed (largely portable; cross-platform fixes applied).
- QA Pipeline Messaging (`qa/SKILL.md`): First pass complete.
- Conversation Analysis (`conversation-analysis.md`): Factory and Grok sections now authored with researched content.

**Next Step**: User to select the next section for deep-dive from the recommended order above. We will analyze the file in detail and apply targeted markup.

**Systematic First-Pass Triage — Complete**

Every skill under `src/` has now received at least a triage-level review for agent-specific content. All identified issues have been either:
- Addressed with first-pass markup + TODO placeholders, or
- Generalized / noted as low-impact.

We are now ready to move into selective deep-dive work on the highest-impact areas (starting with Memory Primitives, as previously discussed).