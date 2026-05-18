---
name: qa-tools
description: QA inspection tools for visual testing -- video frame extraction, screenshot analysis
---

# QA Tools

Tools for inspecting visual artifacts during QA workflows. Use this skill when you need to analyze screen recordings, identify UI regressions, or document visual behavior from test runs.

## When to Use

- Reviewing screen recordings captured during QA or persona testing
- Investigating visual regressions flagged in bug reports
- Extracting key moments from UI walkthrough recordings
- Building visual evidence for bug reports or PR reviews

## Video Frame Extraction

The `video_frames.py` tool extracts frames from a video file at regular intervals, saving them as images that can be inspected with the Read tool.

### Invocation

```bash
cd ~/Source/OMG/agent-tools/skills/qa/tools && uv sync && uv run video_frames.py <video_path>
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--output-dir` | `/tmp/qa-frames/` | Directory for extracted frames |
| `--interval` | `2` | Seconds between frames |
| `--format` | `png` | Output format: `png`, `jpg`, or `webp` |

### Examples

Extract frames every 2 seconds (default):
```bash
cd ~/Source/OMG/agent-tools/skills/qa/tools && uv sync && uv run video_frames.py /tmp/recording.webm
```

Extract frames every half-second for detailed inspection:
```bash
cd ~/Source/OMG/agent-tools/skills/qa/tools && uv sync && uv run video_frames.py /tmp/recording.webm --interval 0.5
```

Save as JPEG to a specific directory:
```bash
cd ~/Source/OMG/agent-tools/skills/qa/tools && uv sync && uv run video_frames.py /tmp/recording.webm --output-dir /tmp/bug-123/ --format jpg
```

## Viewing Extracted Frames

After extraction, use the Read tool to view individual frames. The Read tool supports image files natively:

```
Read /tmp/qa-frames/frame_0000s.png
Read /tmp/qa-frames/frame_0004s.png
```

## Workflow: QA Bug Report

1. **Extract frames** from the screen recording attached to the bug report
2. **Scan the frames** at a coarse interval (every 2-5s) to identify where the issue appears
3. **Re-extract** at a finer interval around the problem timestamp if needed
4. **Read specific frames** to examine the visual state in detail
5. **Document findings** with frame references and timestamps

## Tips

- Start with a coarse interval (2-5s) to get an overview, then narrow down
- Frame filenames include the timestamp (`frame_0002s.png` = 2 seconds in), making it easy to correlate with video playback
- For long recordings, use `--output-dir` to keep frames organized per investigation
- The tool prints each saved path to stdout, so you can pipe or parse the output
- Use `png` for lossless quality when inspecting UI details; use `jpg` for smaller files when reviewing many frames
