# Process payload (runtime adapter contract)

**Load when:** packaging `/workflow` + `/swarm` for another agent runtime (Hermes, custom
operator shell, CI bot), or checking that a harness implements the production line without
rewriting phases.

**SoT remains agent-tools `src/`.** Runtimes **adapt**; they do not fork a second phase table.

## Payload version

```text
process_payload_version: 1
```

Bump when hard contracts change (tracks, claim dialect, runs events, handoff schema, gate
evidence). Soft doc polish does not bump.

## Must implement (adapter surface)

| Contract | Agent-tools home | Runtime obligation |
|----------|------------------|--------------------|
| Principal entry | `/workflow:continue` | Orient → portfolio mode → unit SM or swarm; **never invent NEXT** |
| Planning root | `references/planning-root.md` | Resolve `.agent-tools/planning/` then legacy `./planning/` |
| Tracks | `references/tracks.md` | feature \| micro \| research (+ conventions overrides) |
| Phase skills | refine, plan, execute, review, compound, … | Same gates; same artifacts |
| Claim dialect | `planning/pm-integration.md` | Parse/emit `workflow:claim` / egress lines |
| Runs ledger | `references/runs-ledger.md` | Append events; close-run; optional yield |
| Handoff / return | `references/handoff-package.md` + swarm structured return | Same field names |
| Review evidence | continue `gates.md` | method, date, verdict, P1–P3, disposition |
| Merge policy | conventions | Honor autonomous local merge ratchet; no silent push |
| Memory | `.agent-tools/memory/` + compound | Capture/maintain; no skill mutation |
| Corpus change | Skill source only (`/skills:evolve` when installed) | Never edit process IP from run traces; consumers capture evidence + escalate upstream |

## Must not reimplement

- New NEXT invent heuristics (“pick interesting backlog”)
- Alternate return schema for workers
- Skill self-edit from run traces without evolve
- Always-on gateway / webhooks (runtime product, outside this payload)
- Dual-maintained full skill tree as a second SoT

## Optional (runtime-owned)

| Concern | Notes |
|---------|--------|
| Multi-channel gateway | Maps channel events → `workflow:claim` only |
| Model routing | Operator vs implementer models |
| Cron / schedule | Emit claim or continue invocation |
| Sandbox / cloud workers | Still return structured YAML + disk artifacts |
| Trace export | May import `.agent-tools/runs/events.ndjson` |

## Skill graph (families)

```text
workflow (parent)
  continue | setup | prune | roadmap | brainstorm | refine | plan | execute | review | audit | compound
swarm (parent)
  setup | continue | <goal orchestrator>
git | personify
skills (import | evolve)   # publish-target: project — skill source only, not consumer installs
knowledge (on-demand): clean-architecture | code-patterns | test-strategy | …
```

Adapters may subset **invocable** surfaces but must not drop hard gates when a phase is offered.
`skills` / evolve is **optional** outside the skill-source repo; adapters must still refuse
silent process-IP skill edits.

## Artifact layout (project)

```text
.agent-tools/
  planning/          # preferred planning root
  memory/            # L3-shared
  runs/              # events + ledger + yield
  charter/ swarm/    # when swarm used
```

## Compatibility checklist (dogfood a runtime)

1. Claim named unit → micro or feature classify correctly  
2. Plan approve → same-session execute (default)  
3. Review produces valid evidence line  
4. Local merge only when ratchet green (if conventions allow)  
5. Compound disposition recorded  
6. Event lines appear under `runs/events.ndjson`  
7. Process gap → process memory (+ evolve in skill source, or upstream escalate) — not silent skill edit  

## Related

- Wave 1–2 notes in consumer projects (e.g. software-factory `docs/process-ip-wave*.md`)
- Swarm worker contract: `src/swarm/roles/worker-contract.md`
