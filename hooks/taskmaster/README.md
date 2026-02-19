# Taskmaster — Claude Code Stop Hook

A stop hook that prevents the agent from stopping prematurely. When a response
finishes and the agent is about to stop, this hook intercepts and prompts it
to re-examine whether all work is truly done.

## How It Works

1. **Agent tries to stop** -- the stop hook fires.
2. **The hook checks** for incomplete signals (pending tasks, recent errors)
   by scanning the last 50 lines of the session transcript.
3. **Agent is prompted** to verify: original requests addressed, plan steps
   completed, tasks resolved, errors fixed, no loose ends.
4. **If work remains**, the agent continues. If truly done, it confirms and
   the hook allows the stop on the next cycle.

## Loop Protection

A session-scoped counter (stored in `$TMPDIR/taskmaster/`) limits continuations
to **10 by default**. This prevents infinite loops where the agent never stops.

When the counter reaches the maximum, the hook allows the stop unconditionally
and cleans up the counter file.

## Configuration

Set the `TASKMASTER_MAX` environment variable to control the continuation limit:

```bash
export TASKMASTER_MAX=20  # allow up to 20 continuations
export TASKMASTER_MAX=0   # infinite (relies on transcript analysis only)
export TASKMASTER_MAX=1   # single review pass
```

The default is `10` if not set.

## Registration

Hooks must be manually registered in `~/.claude/settings.json`. Add the
following to your settings file:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/taskmaster/check-completion.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

If you already have a `hooks` section, merge the `Stop` array into it.

## Disabling

To temporarily disable Taskmaster, either:

- **Remove or comment out** the Stop hook entry in `~/.claude/settings.json`.
- **Set `TASKMASTER_MAX=1`** to allow only a single continuation check before
  the agent is permitted to stop.

## Requirements

- **bash** -- the hook script is a bash script.
- **jq** -- used to parse JSON input and produce JSON output.
- **Claude Code** with hooks support enabled.

## References

Taskmaster is based on [blader/taskmaster](https://github.com/blader/taskmaster),
licensed under the [MIT License](https://github.com/blader/taskmaster/blob/main/LICENSE).
