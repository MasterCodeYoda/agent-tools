# Thin routing (skill corpus norm)

**Load when:** adding, restructuring, or extracting skills; running `/skills:evolve` on structure;
horizon extractions that move content between `SKILL.md`, `templates/`, and `references/`.

## Philosophy

> **Thin always-on surface (skills + prompts). Thick, modular, *available* context. Skills stay
> procedurally complete enough to force the right loads and checks — not empty routers.**

| Layer | Role | Shape |
|-------|------|--------|
| **Skill (`SKILL.md`)** | When to run, order of steps, gates, refuse lists, mandatory loads | Thin control plane |
| **Prompt / role** | Instantiation of a turn or worker | Thin; deltas over shared contracts |
| **Context** (`references/`, `templates/`, memory, sibling docs) | Domain truth, catalogs, write-time artifact bodies | Thick on disk; load selectively |

Thickness belongs **in the corpus**, not in every session window. An always-injected encyclopedia is a fat prompt wearing a different hat.

## Preferred layout

| Content kind | Home | Load discipline |
|--------------|------|-----------------|
| Triggers, phase order, hard gates, stop/refuse | `SKILL.md` | Always on when skill is active |
| Write-time artifact bodies (requirements shells, reports) | `templates/` | Load when writing the artifact |
| Catalogs, doctrine essays, API dumps, long examples | `references/` | Load when the topic arises |
| Language / domain deep guides | `languages/`, `references/`, sibling modules | Route from skill; open on demand |

**Dual residence is a bug.** If material lives in a reference, the skill keeps at most a one-line trigger or decision table — not a second full copy.

## Budget guidance (not global hard fails)

Prefer:

- **≤ ~200 lines** for routers and indexes (`code-patterns`, family parents that only dispatch)
- **≤ ~300 lines** for multi-gate orchestrators that must carry hard contracts in-skill
- **Fence ratio** under ~35% of skill body — high fenced bulk usually means templates or catalogs that should leave `SKILL.md`

These are **design targets** for new work and extractions. Pre-existing fat skills may remain allowlisted in `tools/doc-lint-allowlist.txt` until a dedicated extraction unit lands. Do not “fix” line count by deleting procedure.

## What must never leave the skill

Demoting these to optional-only docs is a **regression**:

1. **Hard gates** — plan approval, review evidence schemas, path-not-established, compound routing safety, autonomous-merge ratchets
2. **Mode detection** — file vs PM, decomposition mode, tool-selection rules
3. **Mandatory load lists** — “read X before routing/writing”
4. **Stop / refuse lists** — explicit “does not” contracts

Empty routers that only say “be careful and check the docs” produce variance and skipped gates.

## Extraction rules

1. **Move, don’t delete** — conservation review: no lost gates, no lost mandatory loads.
2. **Skill keeps the control plane** — order, branches, and when to open which file.
3. **Templates at write time** — fenced full documents in skills are the usual smell.
4. **Catalogs in references** — tool/API man pages, pattern encyclopedias, long anti-pattern galleries.
5. **Exemplars** — `code-patterns` (thin router), `visual-design` (checklist + index + refs), `swarm` (orchestrator + roles/refs).

## Automated checks

`tools/doc_lint.py` enforces objective **skill-shape** signals (see module docstring / rule messages):

| Rule | Signal (defaults) |
|------|-------------------|
| `skill-bloat-no-siblings` | `SKILL.md` ≥ **300** lines and **zero** other `.md` files under that skill directory tree |
| `skill-high-fence-ratio` | `SKILL.md` ≥ **200** lines and fenced-code line ratio ≥ **0.35** |

Suppressions for known pre-extraction fat skills use allowlist form:

```text
shape <glob>
```

Remove `shape` entries as extraction units modularize those skills. `/skills:evolve` Tier-1 must treat dual residence and pure catalog dumps as structural gaps when proposing structure changes — cite this norm.

## Related

- `@skills` / `@skills:evolve` — corpus health and structure-changing work
- `src/skills/references/MARKUP.md` — portable markup (orthogonal to layout)
- Horizon: thin-routing remediation (`planning/roadmap.md` when present in a working tree)
