---
name: alpha
description: Fixture family skill exercising agent markup resolution.
user-invocable: true
---

# Alpha

Shared content visible to every agent.

<!-- agent:include claude -->
Claude-only guidance line.
<!-- /agent:include claude -->

<!-- agent:include grok, factory -->
Grok-and-Factory guidance line (spaced agent list).
<!-- /agent:include grok, factory -->

<!-- agent:exclude codex -->
Everyone except Codex sees this line.
<!-- /agent:exclude codex -->

<!-- A plain HTML comment that the publisher must strip. -->

<!--
A multi-line HTML comment.
It must be stripped entirely, not leak into published output.
-->

Inline text survives <!-- this inline comment is stripped --> around comments.

Mentioning `<!-- agent:include claude -->` in backticks is prose, not a directive.

```markdown
<!-- agent:include grok -->
Fenced tag examples and <!-- fenced comments --> publish verbatim.
<!-- /agent:include grok -->
```

<!-- agent:exclude grok -->
Region-filtered fence follows:

```bash
echo "hidden from grok, fenced"
```
<!-- /agent:exclude grok -->

Trailing shared content.
