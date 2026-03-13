# Statusline

A custom status line for Claude Code that displays model info, context usage, git branch, session duration, effort level, and API rate-limit utilization — all inline in the terminal.

## Usage

### Install

```bash
bash tools/statusline/install.sh
```

This will:
- Copy `statusline.sh` to `~/.claude/statusline.sh`
- Back up any existing statusline script
- Add `statusLine` config to `~/.claude/settings.json`

Restart Claude Code after installing.

### Uninstall

```bash
bash tools/statusline/install.sh --uninstall
```

Removes the script and the `statusLine` key from settings.

### Dependencies

- `jq` — JSON parsing
- `curl` — API usage fetch
- `git` — branch/dirty detection

## References

Based on [claude-statusline](https://github.com/kamranahmedse/claude-statusline) by Kamran Ahmed, sanitized for inclusion in agent-tools.
