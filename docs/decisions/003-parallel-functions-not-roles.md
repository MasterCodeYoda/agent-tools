# Parallel dispatches are functions, not agent roles

## Decision

Parallel-mode workers are **scoped functions** (dispatch packets), not named agent personas.

| Concern | Rule |
|---------|------|
| Vocabulary | Prefer *function*, *packet*, *dispatch* — not *role* / *persona* |
| Source + project path | `parallel/functions/` (not `roles/`) |
| Return schema field | `function:` — values `plan` \| `implement` \| `review` \| `resolve-conflict` \| `fix-integration` |
| Config | `function_chain`, `models`, `clis` keyed by those function ids |
| Phase packets | Map to `/work:plan`, `/work:execute`, `/work:review` |
| Ad-hoc functions | `resolve-conflict`, `fix-integration` — first-class; not phase proxies |
| Charter | One shared charter; no per-function personality files |
| Substrate | Same agent kind (harness + model + effort); model map is runtime binding only |
| Legacy | **None** — no `role:` field, no `roles/` path, no planner/implementer key aliases |

## Rationale

1. **Persona roles are a weak proxy.** Parallel mode needs context isolation, a return contract,
   and a procedure — not a cast of characters.
2. **Charter already holds values/process.** Duplicating “who you are” into role files drifts
   from project ground truth.
3. **Ad-hoc functions prove the paradigm.** Conflict and integration fixers are valuable
   *because* they are not “run a work phase in a new context.”
4. **Clean cut.** No dual schemas or alias maps.

## Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| Keep “roles” name, thin prompts only | Vocabulary keeps recruiting persona libraries |
| Legacy `role:` / `roles/` / old model keys | Explicitly rejected — clean cut |
| Drop specialization entirely | Isolation + packet contracts still need function ids |
| Grow CrewAI-style persona cast | Increases spec ambiguity (a top multi-agent failure mode) |
| Build LLM Council as the role system | Council is multi-model *deliberation* — orthogonal |

## Related

- `docs/decisions/001-swarm-collapse-into-workflow.md`
- `docs/decisions/002-work-family-name.md`
- `@work` `parallel/MODE.md`, `functions/*`
