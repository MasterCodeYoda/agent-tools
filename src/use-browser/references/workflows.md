# Browser automation workflow examples

Load on demand from `@use-browser`. Short recipes for MCP and agent-browser.

### Chrome DevTools MCP workflow

```
# Navigate and inspect
mcp__chrome-devtools__navigate_page(url: "https://example.com/form")
mcp__chrome-devtools__wait_for(selector: "form")
mcp__chrome-devtools__take_snapshot

# Interact with form
mcp__chrome-devtools__fill(selector: "[name=email]", value: "user@example.com")
mcp__chrome-devtools__fill(selector: "[name=password]", value: "password123")
mcp__chrome-devtools__click(selector: "button[type=submit]")
mcp__chrome-devtools__wait_for(text: "Welcome")
mcp__chrome-devtools__take_snapshot
```

### Using agent-browser for video recording

```bash
# Explore first, then record a clean demo
agent-browser open https://example.com/demo
agent-browser snapshot -i
# ... explore and plan steps ...

agent-browser record start ./demo.webm
agent-browser open https://example.com/demo
agent-browser fill @e1 "user@example.com"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser record stop
```

### agent-browser standalone (no Chrome)

```bash
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser click @e1
agent-browser screenshot --annotate result.png
```
