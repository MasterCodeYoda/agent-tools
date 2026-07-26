---
project: kevn-docker-primary-deploy
requirements_source: pm
work_item: KEVN-11
pm_tool: linear
session_count: 1
status: execute_in_progress
track: feature
decomposition: deliverable-partition
execution_home: agent-tools
branch: feat/kevn-11-kevin-hermes-image
pending_gate: none
last_transition: "approve&execute — monorepo pack + local image build OK"
linear: https://linear.app/overlund-media/issue/KEVN-11
---

## Progress

### Done in agent-tools (`feat/kevn-11-kevin-hermes-image`)

- [x] D0 migration map (`docs/kevin/MIGRATION.md`)
- [x] D1 `hermes/profile` + docker skeleton
- [x] D2 Dockerfile bakes `dist/hermes` — **local build `kevin-hermes:local` OK**
- [x] D3 compose + entrypoint + `.env.example`
- [x] D4 GHCR workflow `kevin-hermes-image.yml` (main + sha)
- [x] D5 path-of-record runbook + ADR-001 §8 amend + ADR-002 present + README
- [ ] D6 SF full migrate + delete (partial content moved; repo still exists)
- [ ] Push branch + merge main for GHCR publish
- [ ] Compose live dogfood residual if entrypoint/profile install needs tune

### Local verify

```bash
docker build -f hermes/docker/Dockerfile -t kevin-hermes:local .
# skills + revision present in image
```
