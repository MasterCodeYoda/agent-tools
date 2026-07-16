---
name: use-browser
description: Browser automation using Chrome DevTools MCP and the agent-browser CLI. Use when the user needs to navigate websites, fill forms, take screenshots, scrape data, or test web applications.
allowed-tools: Bash(agent-browser:*)
---

# Browser Use

Two complementary approaches:

- **Chrome DevTools MCP** — tools prefixed `mcp__chrome-devtools__*` against a running Chrome instance (when available)
- **agent-browser CLI** — standalone headless browser for CI, cloud, recording, and environments without local Chrome

## When to Use

- Navigate sites, fill forms, take screenshots, scrape or inspect pages
- Record demos, compare pages, run Lighthouse / performance traces
- QA scanning and product research that need a real browser

## Tool Selection

| Prefer Chrome DevTools MCP when | Prefer agent-browser CLI when |
|---------------------------------|-------------------------------|
| Live inspection of the user’s Chrome session / auth | Video recording (`record start/stop`) |
| Snapshots, screenshots, JS eval, console/network debug | Session/profile persistence (`--session`, `--profile`) |
| Form interaction + device emulation | Headless-only / cloud (Browserbase, Browserless, …) |
| Lighthouse and performance traces | PDF export, annotated screenshots, snapshot/screenshot diffs |

No universal best tool — pick by Chrome availability, recording needs, and environment constraints.

## Connection Setup

### MCP → running Chrome

**Preferred (autoConnect):** open Chrome → `chrome://inspect#remote-debugging` → enable remote debugging. MCP connects with no extra config.

**Manual:** start Chrome with `--remote-debugging-port=9222`, then point the MCP server at `--browser-url=http://127.0.0.1:9222`.

```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 &
# Linux: google-chrome --remote-debugging-port=9222 &
# Windows: "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

### Standalone (agent-browser only)

```bash
agent-browser open <url>
agent-browser open <url> --ignore-https-errors   # self-signed certs
agent-browser open <url> --idle-timeout 5m
```

Isolated headless browser; also supports Brave auto-discovery alongside Chrome/Chromium.

## Core loops

### Chrome DevTools MCP

1. Ensure Chrome + MCP connected (above)
2. `navigate_page` / `new_page` → `wait_for` as needed
3. `take_snapshot` (or screenshot) before acting
4. `click` / `fill` / `fill_form` / keys using selectors from the snapshot
5. Re-snapshot after navigation or large DOM changes
6. For tool names and flags → load `references/chrome-devtools-mcp.md`

### agent-browser CLI

1. `agent-browser open <url>`
2. `agent-browser snapshot -i` → use `@eN` refs from the tree
3. Interact (`click`, `fill`, …) with those refs
4. Re-snapshot after navigation or significant DOM changes
5. For full flag/subcommand catalog → load `references/agent-browser-cli.md`  
   (if mismatch with install, prefer `agent-browser --help`)

## Load for depth

| Need | Open |
|------|------|
| Full MCP tool tables + server flags | `references/chrome-devtools-mcp.md` |
| Full agent-browser CLI catalog | `references/agent-browser-cli.md` |
| Worked examples (form, record, standalone) | `references/workflows.md` |

## Related Skills

- **qa** — app scanning and visual inspection
- **product** — competitor research and screenshot comparison

## External docs

- [Agent Browser](https://agent-browser.dev/) — [Changelog](https://agent-browser.dev/changelog)
- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp) — `npx chrome-devtools-mcp@latest --autoConnect`
