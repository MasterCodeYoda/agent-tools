---
name: qa:discover
description: Discover and author NL test specifications through app scanning, doc import, or guided conversation
argument-hint: "[--scan | --import <path> | <area-name> for interactive discovery]"
user-invocable: true
---

# Discover Test Specifications

Build NL test specs by scanning the live app, importing from existing docs, or guided conversation.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine discovery mode:

| Input Pattern | Mode | Action |
|---------------|------|--------|
| `--scan` | Sitemap Scan | Launch browser, explore app, build feature map |
| `--import <path>` | Doc Import | Extract specs from existing markdown/docs |
| `<area-name>` | Interactive | Guide user through spec creation for an area |
| Empty | Auto-detect | Check for sitemap, suggest next step |

## Load Configuration

Read `sentinel.config.yaml` and extract `app.base_url`, `specs.nl_dir`, `specs.seed`, and `auth` settings. If no config exists, tell the user to run `qa:setup` first and stop.

---

## Modes

| Invocation | Mode | Detail |
|------------|------|--------|
| `--scan` | Sitemap scan | **Load** `references/modes/scan.md` |
| `--import <path>` | Import from docs | **Load** `references/modes/import.md` |
| `<area-name>` | Interactive discovery | **Load** `references/modes/interactive.md` |

Always load @qa `references/spec-format.md` and write NL specs via @qa `templates/spec-template.md`
(and seed template when applicable). Priority tiers P0–P3 and persona tagging rules are defined
in the mode refs and spec-format — do not invent a different priority scheme.

## No Arguments — Auto-Detect

If `$ARGUMENTS` is empty:

1. Check if `specs/_sitemap.md` exists

**If sitemap exists:**

Read the sitemap and show discovered areas. Use `AskUserQuestion`:

> "Sitemap found with these areas: [list areas]. Which area would you like to discover specs for? Or type '--scan' to re-scan the app."

Then proceed with interactive discovery for the chosen area.

**If no sitemap:**

> "No sitemap found. Would you like to scan the app first? Run with --scan to explore the app and build a feature map, or provide an area name to start interactive discovery directly."

---

## Key Principles

### Specs Must Be Concrete

Every generated scenario must have:
- A numbered H3 heading with a descriptive title
- Specific step-by-step user actions
- An **Expected:** line that is observable and verifiable

### Persona Tagging Is Required

Every spec needs a `persona` field. This helps the Planner understand who is doing the action and what prior state to assume:
- `new-user` — first-time setup, no existing data
- `power-user` — heavy usage, complex data, advanced features
- `returning-user` — resuming work, existing data present

### Priority Reflects Risk

- P0 — data loss or corruption possible
- P1 — app is unusable without this working
- P2 — meaningful feature, app is still usable without it
- P3 — edge case or boundary condition

### Interactive Over Assumed

When in doubt, ask the user rather than guess. A spec based on real knowledge is worth more than one filled with assumptions.

## Integration Points

### With /qa:setup

Discover depends on `sentinel.config.yaml` produced by setup. If config is missing, direct user to run `/qa:setup` first. Config provides `app.base_url`, `specs.nl_dir`, `specs.seed`, and auth settings.

### With /workflow:audit (qa domain) and planned `/qa:audit`

Discover produces NL specs. Audit evaluates them for drift against the app. When audit finds gaps, it recommends discover to author new specs.

### With @use-browser

Discover's `--scan` mode uses Chrome DevTools MCP (or agent-browser) to explore the app, take snapshots, and build the feature map.

### With Playwright Test Agents

Discover's output (NL specs) feeds directly into Playwright's Planner → Generator pipeline. Specs are the contract between discover (authoring) and Playwright (execution).
