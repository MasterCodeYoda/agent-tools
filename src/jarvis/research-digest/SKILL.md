---
name: jarvis-research-digest
description: >
  Morning external research sweep for Jarvis CoS — web + X signal mapped to in-flight
  projects; short ranked digest with non-obvious pattern matches; email or dry-run.
  Use when running the daily ritual, seeding projects, or composing the digest.
user-invocable: true
---

# Jarvis research digest

Unattended-friendly ritual for **Jarvis** (not Kevin). Scans the **external** internet for
research, trends, announcements, and discussions that are **directly or non-obviously**
related to the operator's in-flight projects. Delivers a short ranked digest.

## Inputs

### Project lens (adaptive state)

Read (and never invent a second SoT for):

```text
$HERMES_HOME/profiles/jarvis/state/projects.md
```

If `HERMES_HOME` unset, prefer the live profile home for this process
(`~/.hermes/profiles/jarvis/state/projects.md` on host layouts).

**Seed format** (markdown):

```markdown
# In-flight projects

- **project-slug** — one-line mission / what "related" means
  - keywords: optional comma list (not the only relevance signal)
  - notes: optional adjacency themes
```

If missing: create a stub and **fail loud** for unattended send (dry-run may continue with a
warning). Optional **auto-suggest**: propose additions at end of digest; do not write without
operator intent unless they asked to apply suggestions.

### Sources (v1)

| In scope | Out of scope (v1) |
|----------|-------------------|
| Web search / open web | HN/Reddit/forums as primary |
| X (public posts/threads) | Internal repo code scans as primary signal |
| | RSS/newsletter firehose (later) |

## Quality bar

- **Short ranked list:** about **5–10** items (not a dump).
- Each item: title/link, **why it matters** to which project(s), **direct vs non-obvious** tag.
- Prefer **high-leverage opportunity** and **pattern-overlap** over keyword hits.
- Skip noise the operator would ignore after one glance.

## Digest schema

```markdown
# Jarvis research digest — YYYY-MM-DD

## Top picks
1. **Title** — url
   - Projects: …
   - Relevance: direct | non-obvious
   - Why: …

## Also notable
…

## Project-list suggestions (optional)
- …
```

## Delivery

### Dry-run (default when email incomplete or `--dry-run`)

Write digest to:

```text
$HERMES_HOME/profiles/jarvis/state/digests/YYYY-MM-DD.md
```

Print path; **do not send**.

### Email (happy path, unattended)

Required env (live profile `.env` — names only in git templates):

- `JARVIS_SMTP_HOST`, `JARVIS_SMTP_PORT`, `JARVIS_SMTP_USER`, `JARVIS_SMTP_PASSWORD`
- `JARVIS_DIGEST_TO`, `JARVIS_DIGEST_FROM`
- Optional: `JARVIS_SMTP_STARTTLS=1`

If any required var missing and not dry-run: **fail loud** (non-zero / clear error). Do not
claim success with empty send.

Send subject: `Jarvis digest — YYYY-MM-DD`. Body: markdown or plain text of the digest.

Implementation may use a small helper script under `hermes/scripts/` when present; otherwise
compose with available host tools. Never log SMTP passwords.

## Unattended safety

- **May:** research, compose, write adaptive state digests, send email when configured.
- **Must not:** rewrite policy `config.yaml` / `SOUL.md`; commit secrets; irreversible non-email acts.
- Policy changes: propose for human promotion to git only.

## Cron shape (host)

```text
# Example — morning local time; adjust TZ on host
hermes -p jarvis cron …  # or script:
#   hermes -p jarvis chat -q "Run jarvis-research-digest for today; send email unless dry-run"
```

Prefer invoking this skill explicitly in the cron prompt. Gateway may already be running for Slack.

## Related

- Profile: `hermes/jarvis-profile/`
- Lanes: `docs/agents/runbooks/multi-agent-config-lanes.md`
- Capabilities: `docs/agents/runbooks/jarvis-capabilities.md`
