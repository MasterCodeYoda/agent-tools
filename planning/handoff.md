# Handoff Document — Agent-Specific Content Audit & Publishing System

**Date**: 2026-05-18  
**Context**: Major phase of making the canonical skill corpus properly portable across agents (Claude, Grok, Factory) while building the supporting mechanical publishing layer.

## 1. What Was Accomplished

- **Full first-pass audit** of agent-specific content across the entire `src/` corpus.
- **Deep dives + final polish** completed on all high and medium priority items:
  - Memory Primitives
  - Conversation History Analysis
  - Playwright Test Agents initialization (`qa:setup`)
  - Worktree handling (across workflow + git skills)
  - Use-Browser
  - QA Pipeline / Sentinel messaging
- **Grok and Factory content** written for the highest-impact files (using the `<!-- agent:include / exclude -->` system).
- **Publishing layer** designed and implemented:
  - `tools/publish-skills.sh` (thin, mechanical, supports `--dry-run`)
  - Integrated into `setup.sh` so running setup automatically publishes then installs the correct agent-specific skills.
- **Architectural decisions locked in**:
  - Agent-specific implementation details live in the relevant skill files (especially git worktree skills).
  - `workflow/SKILL.md` stays high-level and delegates to specialized skills.
  - `publish-target: project` is used for the `skills` meta-skill (installed locally, not globally).
- All previous planning artifacts from this phase were cleaned up.

## 2. Current State of the Corpus

- The skill corpus is now **significantly more portable** than before.
- High and medium priority agent-specific content has been either generalized or properly marked up with agent blocks.
- Lower priority items received at least a light triage pass and minor cleanups.
- The mechanical publishing system is functional and wired into the normal developer workflow (`./setup.sh`).

The corpus is in a good state to begin real usage and testing of the new publishing flow.

## 3. Open / Remaining Work (Suggested Priority)

### High Value / Should Do Soon
- **End-to-end testing of the publishing flow**
  - Run `./setup.sh` as a real user for Claude, Grok, and Factory.
  - Verify that `dist/<agent>/skills/` is generated correctly.
  - Verify that the right skills land in the right places (global vs local project).
  - Test both `--factory-only` and normal modes.
- **Review remaining low-priority items** from the triage for any that deserve deeper treatment (currently considered acceptable as-is).
- **Polish the Grok and Factory sections** in lower-priority files to the same quality level as the high-priority ones (many are still lighter).

### Nice to Have / Future
- Improve `tools/publish-skills.sh` (better error reporting, performance, summary output, handling of non-`.md` files).
- Consider adding a `--check` or validation mode to the publisher.
- Decide on long-term ownership of the `planning/` directory (currently empty after cleanup).
- Possibly add a `CONTRIBUTING.md` or `AGENTS.md` note about how to handle future agent-specific content when authoring new skills.

## 4. Key Conventions & Decisions to Remember

- Use the per-section pattern when adding agent-specific content:
  - General / portable explanation first.
  - Then `<!-- agent:include claude -->`, `<!-- agent:include grok -->`, `<!-- agent:include factory -->` blocks with the implementation details.
- The `skills` meta-skill is deliberately `publish-target: project` — it should only be installed locally in the agent-tools repo, not into users' global skill directories.
- Agent-specific implementation details (especially directory conventions like worktrees) belong in the specialized skills (e.g., the git worktree sub-skills), not in high-level workflow skills.
- Cross-references between agent blocks should be avoided in the published output.

## 5. Recommendations for the Next Session

1. **Start with real usage testing** of `./setup.sh` for at least two different agents. This will quickly surface any remaining rough edges in the publishing or installation logic.
2. Treat any issues found during testing as the new priority list.
3. Once testing feels solid, consider whether a second, lighter pass over the lower-priority files is worth the effort or if the current state is "good enough."

---

**This document is the new baseline.** All previous planning artifacts from this phase have been removed. Future sessions should start from here.

## 6. Follow-up Session (2026-05-18): End-to-End Testing & Fixes

Completed the recommended real-usage testing of the publishing/install flow:

- Ran `./setup.sh` (full mode) for Claude + Grok + Factory.
- Ran `./setup.sh --factory-only`.
- Ran publisher directly with --dry-run and targeted --agents.
- Verified `dist/<agent>/skills/` generation for all three agents.
- Confirmed per-skill symlinks (claude/grok) and rsync copies (factory) land correctly in user-profile (`~/.*/skills/`) and project-local (`./.*/skills/`) locations.
- The `skills` meta-skill correctly stays project-scoped only.

**Issues surfaced and resolved:**

1. **Critical filter bug in `tools/publish-skills.sh`**: `extract_list()` regex did not account for HTML comment closer ` -->` in tag lines (e.g. `<!-- agent:include claude -->`). Agent lists became `claude--` etc., so `include_active` was always false and all `<!-- agent:include ... -->` content was dropped from published output for every agent. Fixed by adding `sub(/[ \t]*-->.*/, "", line)` before the `>` fallback. All worktree, qa, memory, and conversation agent blocks now emit correctly in `dist/`.

2. **Legacy installation incompatibility in `setup.sh`**: When `~/.claude/skills` was a symlink to the old whole-tree (pre-dist model), the `mkdir -p` + `ln -sfn` per-skill logic failed with "No such file or directory". Added one-time migration in `install_skills_for_agent`: if the user-profile skills path is a symlink for claude/grok, rm it (with yellow warning) so a real directory can be created and populated with the new per-skill symlinks. Claude migration path now works cleanly.

3. **Working-tree noise**: The project-scoped `.claude/skills/`, `.grok/skills/`, `.factory/skills/` directories created on every `./setup.sh` (for the meta-skill) were untracked. Added them to `.gitignore` so `git status` stays clean post-setup.

**Verification results:**
- No more mkdir/ln errors for any agent.
- Legacy symlink replacement warning appears exactly once for affected agents.
- `--factory-only` path remains fast and correct.
- Published content for grok/factory/claude in high-value files (worktree-*, qa, memory-primitives, conversation-analysis) matches source intent.
- Light review of remaining marked-up files (import, MARKUP, worktree-delete, workflow/SKILL.md references) showed acceptable quality; no further polish required for this phase.
- `dist/` refresh + installs succeed for all modes.

The mechanical publishing layer and portable corpus are now production-ready for daily use. The handoff testing mandate is complete.

---

**End of handoff** (extended with verification session)