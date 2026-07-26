# Brainstorm: Docker primary deploy surface

Status: Explored  
converged_by: user  
updated: 2026-07-25  
linear: KEVN-11

## Seed Concept

Kevin’s long-lived primary instance should run as a **Docker deploy surface**: Hermes sandboxed in a container, with volume-backed profile/secrets/skills and a bind-mounted project (software-factory git tree). Host and location (Docker Desktop dry-run vs headless Linux) share one compose/volume contract. Laptop-native Hermes install remains optional operator tooling, not the primary path of record. Slack gateway and unattended loops prove against the containerized instance. Process SoT stays agent-tools; this unit is host packaging and repo visibility under lean A.

## The Itch

v1 shipped host-PATH bring-up and Slack packaging against laptop Hermes. The real primary will not live on a developer laptop shell — it runs sandboxed on a machine. Without Docker as SoT, live smoke and wake residuals prove the wrong topology.

## Directions Considered

- **A — Host Hermes + terminal.backend docker only** — sandboxes tools, not the instance / kill: primary still is host install; headless box is still “install Hermes on OS.”
- **B — Docker as primary deploy surface (chosen)** — instance = container; Desktop = fidelity dry-run of headless / kill: if compose+project mounts cannot prove host-visible project writes.
- **C — Custom Kevin image fork only** — full derived image day one / kill: delays path of record; upstream image + Kevin volume/profile ritual is enough for first ship.

## Chosen Direction

**B** — Docker primary deploy surface (upstream `nousresearch/hermes-agent` + Kevin profile/project/skills volumes; compose as path of record). User selected option 2 explicitly; sandbox Hermes regardless of host machine.

## Deliberately Undecided

- Exact compose layout path under repo (`deploy/`, `hermes/docker/`, …)
- Whether day-one needs DinD / docker.sock for nested terminal.backend docker vs local-in-container tools
- Dashboard port exposure and auth provider choices for Desktop vs headless
- Whether Slack live L-ticks complete in this unit or residual after deploy green
- Worktree/cron layout inside the volume for unattended wake re-homing

## Open Questions for Refinement

- [ ] Volume map: single `/opt/data` vs separate project mount path for git SoT
- [ ] How process pack lands (host setup → bind, bake, or init ritual)
- [ ] Profile `kevin` create/apply from dist without clobbering secrets
- [ ] Desktop dogfood DoD vs headless parity checklist split
- [ ] Update KEVN-5/8 runbooks as “secondary” vs new runbook only
