---
name: use-browser
description: Browser automation using Chrome DevTools MCP and the agent-browser CLI. Use when the user needs to navigate websites, fill forms, take screenshots, scrape data, or test web applications.
allowed-tools: Bash(agent-browser:*)
---

# Browser Use

This skill provides browser automation through two complementary tools:
- **Chrome DevTools MCP** (preferred) — tools prefixed `mcp__chrome-devtools__*` that operate on the user's running Chrome
- **agent-browser CLI** — standalone headless browser for recording, CI, cloud providers, and when MCP is unavailable

## Tool Selection

| Use Chrome DevTools MCP when | Use agent-browser CLI when |
|------------------------------|---------------------------|
| Navigation, snapshots, screenshots | Video recording (`record start/stop`) |
| JavaScript evaluation | Session management (`--session`, `--profile`) |
| Click, fill, form interaction | Cloud providers (`-p browserbase`, etc.) |
| Lighthouse audits, perf profiling | State save/load (`auth save/login`) |
| Network/console inspection | PDF export |
| User's normal Chrome with existing auth | `--annotate` labeled screenshots |
| Waiting for conditions | CI/testing or headless-only environments |
| Emulation and device simulation | Diff comparisons (`diff snapshot/screenshot`) |

**Default to MCP tools.** They work with the user's running Chrome, reuse existing cookies/auth, and require no extra browser process.

## Connection Setup

### autoConnect (primary)

The Chrome DevTools MCP server uses `--autoConnect` to connect to the user's running Chrome automatically. One-time setup:

1. Open Chrome and navigate to `chrome://inspect#remote-debugging`
2. Enable remote debugging

MCP tools then work automatically — no port management, no dedicated profile.

### Port-based CDP (fallback)

For sandboxed or Docker environments where autoConnect isn't available:

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 &
```

Then configure MCP with `--browser-url=http://127.0.0.1:9222`.

### Standalone (agent-browser only)

When no Chrome instance is available:

```bash
agent-browser open <url>
agent-browser open <url> --ignore-https-errors   # Accept self-signed certs
agent-browser open <url> --idle-timeout 5m        # Auto-shutdown after inactivity
```

Launches an isolated headless browser managed by agent-browser. Also supports Brave Browser auto-discovery alongside Chrome/Chromium.

## Chrome DevTools MCP Reference

All tools are prefixed `mcp__chrome-devtools__`. Use these as your primary browser automation interface.

**Server flags:** `--slim` (minimal 3-tool mode for token savings), `--isolated` (temporary profile with auto-cleanup), `--headless`, `--performance-crux` (CrUX field data in perf traces, on by default). Supports `pageId` routing for parallel multi-agent workflows on separate tabs.

### Navigation
| Tool | Purpose |
|------|---------|
| `navigate_page(url)` | Navigate to URL |
| `new_page(url)` | Open new tab |
| `close_page` | Close current tab |
| `list_pages` | List all open tabs |
| `select_page(index)` | Switch to tab by index |

### Inspection
| Tool | Purpose |
|------|---------|
| `take_snapshot` | Full accessibility tree (like `snapshot -i`) |
| `take_screenshot` | Screenshot of current page |
| `take_memory_snapshot` | Heap snapshot for memory analysis |

### Interaction
| Tool | Purpose |
|------|---------|
| `click(selector)` | Click element |
| `fill(selector, value)` | Fill input field |
| `fill_form(fields)` | Fill multiple form fields at once |
| `type_text(text)` | Type text character by character |
| `press_key(key)` | Press keyboard key |
| `hover(selector)` | Hover over element |
| `drag(source, target)` | Drag and drop |
| `upload_file(selector, paths)` | Upload files to input |

### JavaScript
| Tool | Purpose |
|------|---------|
| `evaluate_script(expression)` | Run JavaScript in page context |

### Dialogs
| Tool | Purpose |
|------|---------|
| `handle_dialog(accept, text)` | Accept/dismiss browser dialogs |

### Waiting
| Tool | Purpose |
|------|---------|
| `wait_for(selector, options)` | Wait for element, text (supports any-match text arrays), or condition |

### Emulation
| Tool | Purpose |
|------|---------|
| `emulate(device)` | Emulate device (viewport, user agent) |
| `resize_page(width, height)` | Set viewport dimensions |

### Analysis
| Tool | Purpose |
|------|---------|
| `lighthouse_audit(categories)` | Run Lighthouse performance/a11y/SEO audit |
| `performance_start_trace` | Begin performance trace recording |
| `performance_stop_trace` | End trace and get results |
| `performance_analyze_insight` | Analyze recorded trace data |

### Debugging
| Tool | Purpose |
|------|---------|
| `list_console_messages` | View all console output |
| `get_console_message(id)` | Get specific console message |
| `list_network_requests` | View all network activity |
| `get_network_request(id)` | Get specific request details |

## agent-browser CLI Reference

v0.21.4 — Rust rewrite. Install: `brew install agent-browser && agent-browser install`

### Core workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. Interact using refs from the snapshot
4. Re-snapshot after navigation or significant DOM changes

### Navigation
```bash
agent-browser open <url>      # Navigate to URL
agent-browser back            # Go back
agent-browser forward         # Go forward
agent-browser reload          # Reload page
agent-browser close           # Close browser
```

### Snapshot (page analysis)
```bash
agent-browser snapshot            # Full accessibility tree (traverses iframes)
agent-browser snapshot -i         # Interactive elements only (recommended)
agent-browser snapshot -c         # Compact output
agent-browser snapshot -d 3       # Limit depth to 3
agent-browser snapshot -s "#main" # Scope to CSS selector
agent-browser snapshot --selector "#main"  # Scope to element subtree
```

### Interactions (use @refs from snapshot)
```bash
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser focus @e1           # Focus element
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
agent-browser drag @e1 @e2        # Drag and drop
agent-browser upload @e1 file.pdf # Upload files
agent-browser download @e1 ./out  # Download file by clicking element
```

### Get information
```bash
agent-browser get text @e1        # Get element text
agent-browser get html @e1        # Get innerHTML
agent-browser get value @e1       # Get input value
agent-browser get attr @e1 href   # Get attribute
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
agent-browser get count ".item"   # Count matching elements
agent-browser get box @e1         # Get bounding box
agent-browser get styles @e1      # Get computed styles
agent-browser get cdp-url         # Get Chrome DevTools Protocol URL
```

### Check state
```bash
agent-browser is visible @e1      # Check if visible
agent-browser is enabled @e1      # Check if enabled
agent-browser is checked @e1      # Check if checked
```

### Screenshots & PDF
```bash
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page
agent-browser screenshot --annotate  # Labeled screenshot with numbered elements and legend
agent-browser pdf output.pdf      # Save as PDF
```

### Video recording
```bash
agent-browser record start ./demo.webm    # Start recording
agent-browser click @e1                   # Perform actions
agent-browser record stop                 # Stop and save video
```

### Diff comparisons
```bash
agent-browser diff snapshot              # Compare current vs last snapshot
agent-browser diff screenshot --baseline # Compare current vs baseline image
agent-browser diff url <u1> <u2>         # Compare two pages
```

### Wait
```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait milliseconds
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --url "**/dashboard"    # Wait for URL pattern
agent-browser wait --load networkidle      # Wait for network idle
agent-browser wait --fn "window.ready"     # Wait for JS condition
```

### Mouse control
```bash
agent-browser mouse move 100 200      # Move mouse
agent-browser mouse down left         # Press button
agent-browser mouse up left           # Release button
agent-browser mouse wheel 100         # Scroll wheel
```

### Keyboard (no selector)
```bash
agent-browser keyboard type "text"         # Type with real keystrokes
agent-browser keyboard inserttext "text"   # Insert text without key events
```

### Semantic locators (alternative to refs)
```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
agent-browser find first ".item" click
agent-browser find nth 2 "a" text
```

### Browser settings
```bash
agent-browser set viewport 1920 1080      # Set viewport size
agent-browser set device "iPhone 14"      # Emulate device
agent-browser set geo 37.7749 -122.4194   # Set geolocation
agent-browser set offline on              # Toggle offline mode
agent-browser set headers '{"X-Key":"v"}' # Extra HTTP headers
agent-browser set credentials user pass   # HTTP basic auth
agent-browser set media dark              # Emulate color scheme
```

### Cookies & Storage
```bash
agent-browser cookies                     # Get all cookies
agent-browser cookies set name value      # Set cookie (supports --url, --domain, --path, --httpOnly, --secure, --sameSite, --expires)
agent-browser cookies clear               # Clear cookies
agent-browser storage local               # Get all localStorage
agent-browser storage local key           # Get specific key
agent-browser storage local set k v       # Set value
agent-browser storage local clear         # Clear all
```

### Network
```bash
agent-browser network route <url>              # Intercept requests
agent-browser network route <url> --abort      # Block requests
agent-browser network route <url> --body '{}'  # Mock response
agent-browser network unroute [url]            # Remove routes
agent-browser network requests                 # View tracked requests
agent-browser network requests --filter api    # Filter requests
```

### Tabs
```bash
agent-browser tab                 # List tabs
agent-browser tab new [url]       # New tab
agent-browser tab 2               # Switch to tab
agent-browser tab close           # Close tab
```

### Authentication & Profiles
```bash
agent-browser --profile ~/.myapp open <url>      # Persistent session profile
agent-browser --session-name myapp open <url>     # Auto-save/restore state by name
agent-browser --auto-connect open <url>           # Reuse running Chrome's auth
agent-browser auth save mysite --url https://example.com --username user  # Save credentials
agent-browser auth login mysite                   # Login with saved credentials
agent-browser auth list                           # List saved auth profiles
agent-browser auth delete mysite                  # Delete auth profile
```

### Inspect & Clipboard
```bash
agent-browser inspect                    # Open Chrome DevTools for active page
agent-browser clipboard read             # Read clipboard contents
agent-browser clipboard write "text"     # Write to clipboard
```

### Cloud Providers
```bash
agent-browser -p browserbase open <url>  # Use Browserbase
agent-browser -p browserless open <url>  # Use Browserless
agent-browser -p kernel open <url>       # Use Kernel (stealth mode, persistent profiles)
agent-browser -p ios open <url>          # iOS Simulator (requires Xcode + Appium)
```

### Sessions (parallel browsers)
```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

### Batch execution
```bash
echo '[["open","https://a.com"],["screenshot","a.png"]]' | agent-browser batch --bail --json
```

### Network capture (HAR)
```bash
agent-browser network har start                # Begin HAR recording
agent-browser network har stop ./trace.har     # Stop and export HAR 1.2
```

### Debugging
```bash
agent-browser open example.com --headed   # Show browser window
agent-browser console                     # View console messages
agent-browser errors                      # View page errors
agent-browser highlight @e1               # Highlight element
agent-browser trace start                 # Start recording trace
agent-browser trace stop trace.zip        # Stop and save trace
agent-browser profiler start              # Start DevTools profiler
agent-browser profiler stop profile.json  # Stop and save profile
```

### Self-update
```bash
agent-browser upgrade                    # Auto-detects install method (npm/brew/cargo)
```

### JavaScript
```bash
agent-browser eval "document.title"   # Run JavaScript
```

### JSON output (for parsing)
```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```

## Examples

### MCP-first workflow (preferred)

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
mcp__chrome-devtools__take_snapshot  # Verify result
```

### agent-browser for video recording

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

## References
- [Agent Browser documentation](https://agent-browser.dev/) — [Changelog](https://agent-browser.dev/changelog)
- [Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp) — `npx chrome-devtools-mcp@latest --autoConnect`
