# Model / runtime policy (effort ceilings)

**Load when:** packaging a host adapter (Hermes, automation, multi-model router), pre-wake
automation, swarm worker dispatch, or when the user/host is choosing reasoning effort for
implement models.

**Process SoT stays model-agnostic.** This file states **runtime-owned** defaults. Do **not**
embed lab leaderboards or “always use model X” tables in process skills.

## Why this exists

Frontier models differ in how **reasoning effort** interacts with task fidelity:

- **Sol-class (high / ultra / max):** often derails — leaves the assigned task, chases nits,
  multi-day loops, or untraceable scope expansion. Medium (or lower) is the usable default for
  task-bound work. Persistence-cheerleading system text makes high-effort overstep worse.
- **Opus-class:** may chase a strong adjacent finding with some traceability; still needs
  **scope freeze** and stop rules — prefer medium for long drive; high only with short scope
  and human watch.
- **Cost/speed implementers (e.g. Grok 4.5 class):** usually fine at default/medium for
  implement; research windows may use higher when the host isolates them.

These are **operational defaults**, not benchmarks. Hosts measure and adjust.

## Defaults

| Context | Default effort | High / ultra |
|---------|----------------|--------------|
| **Unattended** (cron, pre-wake, Hermes factory automation, headless continue) | **medium** hard cap | **Forbidden** unless explicit ops override on the run |
| **Interactive** human-watched session | **medium** soft default | Allowed with user opt-in; warn if host can detect high on Sol-class |
| **Swarm implement workers** | **medium** hard default | Only if orchestrator config explicitly raises and scope is frozen |
| **Research / ticket-hidden research window** | host default or medium | Higher OK when window is disposable and isolated |

## Scope freeze (all models, mandatory for high effort)

When effort is above medium **or** the worker is Sol-class implementer:

1. State **Goal** and **Done** in the task brief.  
2. State **Not now** — nits and adjacent bugs: **report only**, do not fix unless leaving them
   open means the task is genuinely incomplete.  
3. If scope must expand significantly → **stop and ask** (or phase-return `HUMAN_STEER` /
   `PROBLEM_REFRAMED`).  
4. No persistence cheerleading (“keep going until fully solved”, “be thorough beyond the
   ticket”) in system/profile text for these runs.

## Hermes binding (recommended)

| Surface | Policy |
|---------|--------|
| Unattended / cron / pre-wake | Thinking/effort **≤ medium**; refuse or force-down if host reports high |
| Interactive Hermes session | Default medium; surface one-line warn if user selects high on Sol-class |
| Profile / SOUL | Point at this file; do not fork a second phase table |

Exact knobs are host-specific — bind real config keys in the Hermes/Kevin adapter, not in every
skill body. Publish target: `agent:include hermes` notes or Hermes profile docs when present.

## Soft-check (automation)

When entry is automation-shaped (`pre-wake-checklist.md`) and the host can report effort:

- If Sol-class **and** effort high/ultra → warn and **force medium** when conventions say so
  (personal factory / Hermes default: force).  
- Interactive sessions: warn only unless project conventions demand a hard cap.

## Related

- `process-payload.md` — runtime adapter contract (effort ceiling is optional runtime-owned)  
- `approval-boundaries.md` — autonomous vs escalate  
- `pre-wake-checklist.md` — unattended entry  
- `context-engineering.md` — instruction budget; no persistence theater  
