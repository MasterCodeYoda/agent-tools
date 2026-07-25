# Control-plane family is named `work`

## Decision

The agent-tools engineering control plane (formerly the `workflow` skill family) is named
**`work`**.

| Surface | Form |
|---------|------|
| Parent / status | `/work` |
| Drive | `/work:continue` |
| Phases | `/work:setup`, `:roadmap`, `:brainstorm`, `:refine`, `:plan`, `:execute`, `:review`, `:audit`, `:compound`, `:maintain` |
| Source tree | `src/work/` |
| Claim dialect | `work:claim` / `work:resume` (canonical) |
| Parallel mode | unchanged as a *mode* under continue; on-disk `.agent-tools/parallel/` |

Project charter file **`.agent-tools/charter/workflow.md`** keeps its filename — it is the
charter “how we move” section, not the skill family.

## Rationale

1. **Zero teach.** `/work` and `/work:continue` need no metaphor onboarding (unlike plant,
   forge, swarm duals).
2. **Grok collision.** Platform bare `/workflow` launches Rhai multi-agent scripts; a same-named
   skill family loses to the built-in. Renaming the process family removes the fight.
3. **One control plane.** After swarm collapsed into continue’s parallel mode, a single short
   noun is enough; no need for industrial brand energy.

## Alternatives considered

| Name | Why not |
|------|---------|
| Keep `workflow` | Collides with Grok built-in; longer; “workflow” is overloaded industry jargon. |
| `process` | More accurate for “control plane,” higher stiffness, more teach than `work`. |
| `factory` | Collides with Factory agent and software-factory repos. |
| `forge` / `line` / `mill` | Catchier; extra teach cost; user optimized for zero teach. |

## Legacy

- Ingress/egress claim tags and PM labels with `workflow:` prefix are **accepted** where they
  still appear on issues; new authoring uses `work:`.
- Re-run `./setup.sh` after pull so installed agent skill trees prune `workflow*` and install
  `work*`.
