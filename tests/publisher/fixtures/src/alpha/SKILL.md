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

<!-- agent:include grok,factory -->
Grok-and-Factory guidance line.
<!-- /agent:include grok,factory -->

<!-- agent:exclude codex -->
Everyone except Codex sees this line.
<!-- /agent:exclude codex -->

<!-- A plain HTML comment that the publisher must strip. -->

Trailing shared content.
