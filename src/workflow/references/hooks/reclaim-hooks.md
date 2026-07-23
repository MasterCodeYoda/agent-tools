# Mid-item reclaim hooks (optional)

**Load when:** installing or authoring host hooks that assist the context-compact protocol.

These hooks **do not fully automate** reclaim. They:

1. Detect the agent’s mid-item **signal** after WRITE  
2. Discourage treating the turn as “done” without a reclaim path  
3. Re-seed resume context after the user/orchestrator runs `/clear` or `/new`  

Full auto clear/continue is deferred to an outer orchestration system (or the human driver).

## Signal

After mid-item WRITE, the agent’s final message must include:

````markdown
```yaml
workflow_reclaim:
  kind: mid-item
  unit: <path>
  reclaim: clean-session
  continue: workflow:continue
  host_command: /clear
```
````

## Reference scripts

Bundled under this directory:

| Script | Role |
|--------|------|
| `stop-reclaim-gate.sh` | **Stop** hook: if signal present, block stop (or inject feedback) with host_command + continue |
| `session-start-reclaim.sh` | **SessionStart** hook: if reclaim-pending marker exists, inject resume_loads guidance |

Copy or symlink into host hook config (paths below). Mark executable (`chmod +x`).

Requires `jq` on PATH.

## Pending marker

Scripts may write:

```text
.agent-tools/reclaim-pending.json
```

in the project cwd (or planning-root parent). Shape:

```json
{
  "kind": "mid-item",
  "unit": ".agent-tools/planning/smoke-unit",
  "continue": "workflow:continue",
  "host_command": "/clear",
  "written_at": "ISO-8601"
}
```

Clear the file after successful SessionStart inject (or after continue begins).

## Grok Build

Hooks: `~/.grok/hooks/*.json` or project `.grok/hooks/` (trust required for project).

**Stop** (filter `reason == end_turn` in script):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${GROK_PROJECT_DIR:-.}/path/to/stop-reclaim-gate.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${GROK_PROJECT_DIR:-.}/path/to/session-start-reclaim.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

Stop input includes `lastAssistantMessage` (camelCase on Grok). Script should allow stop when
no signal is present.

Grok reclaim command for clean-session: **`/new`** (alias `/clear`).

## Claude Code

Settings: `~/.claude/settings.json` or project `.claude/settings.json`.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-reclaim-gate.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "clear",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start-reclaim.sh"
          }
        ]
      }
    ]
  }
}
```

Also match `startup` if you open a new session after `/clear` depending on version. Claude
clean-session command: **`/clear`**. Optional stay-in-thread: `/compact` with focus (not default).

Claude Stop / SessionStart JSON field names may be snake_case (`last_assistant_message`,
`hook_event_name`). The reference scripts accept both.

## OpenCode

Prefer a small plugin that on session end/new reads the same marker file and prints or injects
resume instructions. Default reclaim remains **new/clear session**; auto-compaction is not a
substitute for WRITE + signal.

## What hooks must not do

- Shell-out “fake” slash commands that do not clear the TUI session  
- Delete IC or planning artifacts  
- Auto-merge or auto-continue portfolio invent  
- Run on end-of-item handoff messages (no `workflow_reclaim` signal)  

## Related

- Protocol: `../context-compact.md`  
- Agent compact capability rows: `@skills` `references/agents/`  
