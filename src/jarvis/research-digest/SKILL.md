---
name: research-digest
description: >
  Morning external research & trending brief for Jarvis CoS — world/politics, AI/tech,
  venture insights, and portfolio & markets, ranked to the operator lens. Use for the
  daily ritual, dry-run, or email digest composition.
user-invocable: true
---

# Research digest (morning brief)

Unattended-friendly morning brief for **Jarvis** (not Kevin).

This is **not** a monorepo news scraper. It is a **short executive briefing**:

1. What is moving in the world (politics, AI/tech, markets).  
2. What of that **matters for this operator** — in-flight projects, standing interests, **and** investment portfolio.  
3. Non-obvious connections (pattern match), not keyword dumps about a single tool/repo.

**Voice:** The operator runs **startup-shaped** ventures (sometimes inside a corporate or multi-entity shell) and also holds a **capital portfolio**. Do **not** call them “founder” in section titles unless their lens files say so. Reserve the word **portfolio** for **capital / markets**, not for “list of software projects.”

## Inputs (adaptive state — all under profile `state/`)

Read every file that exists. **Do not invent a second SoT.** Prefer:

```text
$HERMES_HOME/profiles/jarvis/state/projects.md     # in-flight ventures / products (required for full ritual)
$HERMES_HOME/profiles/jarvis/state/interests.md    # standing themes / beat (strongly recommended)
$HERMES_HOME/profiles/jarvis/state/priorities.md   # optional: this-week focus
$HERMES_HOME/profiles/jarvis/state/portfolio.md    # capital portfolio lens (recommended for Portfolio & markets)
```

If `HERMES_HOME` unset, use the live profile home for this process  
(`…/profiles/jarvis/state/` on host or Docker volume layouts).

### `projects.md` (project / venture lens)

Things being **built or operated** — not investment holdings.

```markdown
# In-flight projects

- **project-slug** — one-line mission / what “related” means
  - keywords: optional (hints only — not the only relevance signal)
  - notes: adjacency, stakeholders, risks
```

### `interests.md` (standing lens)

Broader than active tickets. Topics for **ongoing ambient awareness**.

```markdown
# Standing interests

## Domains (always scan)
- AI / agents / models / infra
- Developer tooling & platforms
- Technology industry & regulation
- News & politics (operator-relevant geopolitics, policy, elections)
- Public markets & macro (as context for Portfolio & markets)
- …

## People / orgs to watch (optional)
- …

## Explicit deprioritize (optional)
- Topics to skip or rank last (e.g. pure meme-coin noise)
```

### `priorities.md` (optional temporary boost)

```markdown
# This week
- …
```

### `portfolio.md` (capital / investment lens)

**Reserved meaning:** investable assets and market themes — **not** the software venture list.

**Default when seeding a new instance** (operator may edit): major **US indexes** (S&P 500, Nasdaq-100, Russell 2000, Dow) + **BTC/ETH** (and broader crypto only when material). No account numbers.

```markdown
# Capital portfolio lens

## Holdings & themes (names/tickers OK; no account numbers or secrets)
### Major US indexes
- **SPY / S&P 500** — broad US large-cap beta
- **QQQ / Nasdaq-100** — growth / mega-cap tech beta
- **IWM / Russell 2000** — small-cap / domestic cycle
- **DIA / Dow** — blue-chip tone

### Crypto
- **BTC** — bitcoin
- **ETH** — ethereum
- **Theme: broader crypto beta** — only when material to BTC/ETH or policy

### Cross-cutting (optional)
- **Theme: AI infra / semis**, **rates & USD**, …

## Explicit deprioritize
- Meme-coin / day-trading noise; illiquid microcaps unless listed

## Access notes (optional)
- v1: manual file SoT (Robinhood MCP deferred)
```

If `portfolio.md` is missing: seed/use the **default index + BTC/ETH** lens above for **Portfolio & markets**, and note “using defaults” in **Meta**. Do **not** invent personal holdings beyond that public default book.

### Missing files

| File | Dry-run | Unattended email |
|------|---------|------------------|
| `projects.md` missing | Warn; continue with interests if present | Prefer **fail loud** |
| `interests.md` missing | Warn; stub + defaults | Proceed with defaults; note in Meta |
| `portfolio.md` missing | Markets-only subsection; note in Meta | Same — never invent positions |

**Default domains** when interests are thin: AI & agents, developer platforms, major tech/regulatory news, material political news, macro/markets that affect tech or listed themes.

## Research method (anti-narrowing)

### Must cover (every run)

| Bucket | Intent | Rough share |
|--------|--------|-------------|
| **World & politics** | Material headlines an informed operator should know | ≥ 1–2 if anything real moved |
| **AI & technology** | Models, infra, platforms, regulation, labs, big vendors | ~25–35% |
| **Venture insights** | Startup-shaped **build/operate** signal mapped to `projects.md` (product, GTM, talent, packaging, leverage) — **not** capital portfolio | ~20–30% |
| **Portfolio & markets** | Macro/markets **plus** relevance to `portfolio.md` holdings/themes | ~15–25% when lens exists; thinner if not |
| **Also notable** | Overflow with **required** source links | rest |

**Do not** use section titles:

- “Work-adjacent” (corporate IC framing)  
- “Founder insights” (not accurate for all ventures)  
- “Project signal” (superseded by **Venture insights**)  
- “Portfolio insights” alone for **venture/project** news (**portfolio** = capital)

### Hard rules

1. **Project balance:** If ≥3 top picks all cite the **same software project** (or the same product name, e.g. only Hermes/agent-tools), **rewrite**.  
2. **Keywords are hints, not filters.** Start from **trending** queries in the domains above, *then* score against projects / interests / portfolio.  
3. **Direct vs non-obvious:** Prefer some **non-obvious** links (why this story matters for a builder **or** a capital holder).  
4. **Provenance required:** Every entry must include a **source URL**.  
   - Numbered items: title + bare `https://…` URL (or markdown link with a real URL).  
   - **Also notable** is **not** exempt.  
   - No credible link → **drop** the item.  
   - Prefer primary sources over aggregators when both exist.  
5. **Skip** listicle spam, pure vendor SEO, and one-glance noise.  
6. **Sources (v1):** web + X when available. Live brokerage balances are **out of band** unless a configured read-only path exists (see Access below) — never paste secrets into digests.  
7. **No position advice:** Portfolio section is situational awareness, not buy/sell recommendations.

### Query pattern (suggested)

- World/politics last 24–48h  
- AI/tech / infra / regulation  
- 1–2 searches per **distinct** project theme (not five monorepo variants)  
- Markets/macro + **one search per major holding or theme** in `portfolio.md`  
- Interest-domain deep dives as needed  

## Quality bar

- **~8–14** items across sections (short enough for ~3 minutes).  
- Each item: **title + source URL**, lens tags, **direct | non-obvious**, one-line **why**.  
- High-leverage pattern-overlap over keyword hits.

## Digest schema (markdown SoT)

```markdown
# Morning brief — YYYY-MM-DD

> One-sentence executive line (what mattered today).

## World & politics
1. **Title** — url
   - Lens: …
   - Relevance: direct | non-obvious
   - Why: …

## AI & technology
1. **Title** — url
   - Lens: …
   - Relevance: …
   - Why: …

## Venture insights
1. **Title** — url
   - Projects: slug-a, slug-b (optional)
   - Relevance: …
   - Why: …

## Portfolio & markets
1. **Title** — url
   - Holdings/themes: TICKER, theme-name (from portfolio.md when known)
   - Relevance: …
   - Why: …

## Also notable
- **Title or claim** — url   ← link required

## Meta
Reflection **on this brief itself** (not another news item).

- Coverage gaps today: …
- Suggested lens edits (projects / interests / portfolio — do not write unless asked): …
- Feedback for next run: …
```

Omit empty sections rather than padding. Do **not** title Meta as “Lens notes.”

## Access: capital portfolio data (how Jarvis learns holdings)

| Tier | Mechanism | Secrets? | Notes |
|------|-----------|----------|--------|
| **A — Day-1 (always on)** | Operator-maintained `state/portfolio.md` (tickers, themes, one-line thesis) | No | Adaptive lane; backup with other state text; good enough for relevance ranking |
| **B — Structured export** | Periodic CSV/JSON drop into `state/portfolio-holdings.json` (or similar) from brokerage export | File on volume only | Cron or manual; skill reads allowlisted paths; **no** account numbers |
| **C — Live read-only API / MCP** | e.g. brokerage MCP or API token with **read-only** scopes | Secrets lane (`.env` / auth) | Optional; fail soft to Tier A if unavailable; never trade |

**Jarvis product pack** does not require live brokerage for v1. Prefer Tier A with the **default US indexes + BTC/ETH** seed; promote to B/C (e.g. Robinhood MCP) later when the operator enables it.

When live access exists later: refresh or propose updates to `portfolio.md` only with operator intent; digests cite **public** news URLs, not raw account payloads.

## Delivery

### Dry-run

Write `$HERMES_HOME/profiles/jarvis/state/digests/YYYY-MM-DD.md` — print path; do not send.

### Email (mandatory helper — no ad-hoc SMTP)

**Sole send path:** `jarvis-send-digest.sh`. It loads branded **multipart** plain+HTML.  
Do **not** invent `smtplib` / `MIMEText` / “python email tests.” Do **not** use Hermes `email/himalaya` or other mail skills (not in the jarvis pack).

**Binary location (try in order):**

1. `/opt/jarvis/bin/jarvis-send-digest.sh` (Docker image — production)  
2. `hermes/scripts/jarvis-send-digest.sh` (monorepo lab only)

**Required env (secrets lane — already on durable volume when configured):**  
`JARVIS_SMTP_HOST`, `JARVIS_SMTP_PORT`, `JARVIS_SMTP_USER`, `JARVIS_SMTP_PASSWORD`,  
`JARVIS_DIGEST_TO`, `JARVIS_DIGEST_FROM`  
Optional: `JARVIS_SMTP_STARTTLS`, `JARVIS_DIGEST_FROM_NAME`, Slack footer deep-link env  

**How to treat “is email configured?”**

1. Confirm helper exists and is executable.  
2. Export `JARVIS_*` from profile `.env` into the shell **without printing values** (line-wise `export KEY=…` from `profiles/jarvis/.env`, or rely on container env if already injected).  
3. Optional once:  
   `jarvis-send-digest.sh --file $DIGEST_PATH --dry-run`  
   If dry-run prints `would send` and From/To placeholders (not “missing env”), config is ready — **do not** write python probes.  
4. Send:  
   `jarvis-send-digest.sh --file $HERMES_HOME/profiles/jarvis/state/digests/YYYY-MM-DD.md`  
5. If helper missing or dry-run fails missing env → **fail loud** to the operator. Never fall back to raw SMTP.

Subject: `Morning brief — YYYY-MM-DD` (**no** agent name).  
Markdown on disk is SoT; **HTML packaging is the helper’s job** — skipping it produces plain markdown mail (regression).

## Continuous improvement

| Horizon | Mechanism |
|---------|-----------|
| **Same day** | Slack: “care more about X / less about Y” → adaptive lens files |
| **Weekly** | Review **Meta**; prune projects; update portfolio themes |
| **Skill evolution** | agent-tools pack when process quality drifts |
| **Never silent** | No silent policy commits |

## Unattended safety

- **May:** research, compose digests, send email **only** via `jarvis-send-digest.sh` when configured.  
- **Must not:** ad-hoc SMTP/python email; himalaya or non-jarvis mail skills; commit secrets; irreversible non-email acts; invent holdings; give trade instructions as advice.  

## Cron shape

```text
hermes -p jarvis chat -q "Run research-digest for today; buckets: world, AI/tech, venture insights, portfolio & markets; every item needs a source URL; write state/digests; send email unless dry-run"
```

## Related

- Profile: `hermes/jarvis-profile/`
- Lanes: `docs/agents/runbooks/multi-agent-config-lanes.md`
- Capabilities: `docs/agents/runbooks/jarvis-capabilities.md`
- Email helper: `hermes/scripts/jarvis-send-digest.sh`
