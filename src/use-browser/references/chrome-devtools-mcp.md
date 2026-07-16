# Chrome DevTools MCP reference

Load on demand from `@use-browser` when you need full tool names, server flags, or category detail.

## Overview

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
| `take_heapsnapshot` | Heap snapshot for memory analysis |

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
