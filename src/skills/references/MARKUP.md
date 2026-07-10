# Embedded Markup Specification

**Status**: Draft  
**Purpose**: Define the lightweight markup used inside canonical skill files to express agent-specific content.

---

## 1. Purpose

The Embedded Markup allows authors (and the `skills:import` skill) to mark sections of a skill that should only appear for specific target agents (Claude, Grok, Factory, etc.). This enables a single canonical source to cleanly support multiple agent surfaces without heavy templating.

The mechanical publishing layer uses this markup to include or exclude content when generating artifacts for `dist/`.

---

## 2. Syntax

The markup uses standard HTML comment syntax with an `agent:` prefix.

### Include Block

Content inside an `include` block is **only** shown for the listed agents.

```markdown
<!-- agent:include claude -->
This behavior is specific to Claude Code.
<!-- /agent:include claude -->
```

### Exclude Block

Content inside an `exclude` block is shown for **all agents except** those listed.

```markdown
<!-- agent:exclude factory -->
This section does not apply to Factory.
<!-- /agent:exclude factory -->
```

### Multiple Agents

Use a comma-separated list:

```markdown
<!-- agent:include claude,grok -->
This applies to both Claude and Grok.
<!-- /agent:include claude,grok -->

<!-- agent:exclude factory,claude -->
This is hidden from Factory and Claude.
<!-- /agent:exclude factory,claude -->
```

### Regular Comments

Any standard HTML comment is allowed and will be stripped during publishing:

```markdown
<!-- This note explains why the following section is Claude-only -->
<!-- agent:include claude -->
...
<!-- /agent:include claude -->
```

---

## 3. Semantics

| Construct              | Behavior |
|------------------------|----------|
| No markup              | Included for **all** agents (default) |
| `<!-- agent:include X,Y -->` | Only included for agents X and Y |
| `<!-- agent:exclude X,Y -->` | Included for everyone **except** X and Y |

- Unmarked content is always treated as “include for all”.
- `include` is an allow-list.
- `exclude` is a deny-list.
- Alternative versions of content are expressed by using `include` / `exclude` combinations (no dedicated “alternative” syntax is required).

---

## 4. Agent Names

- Agent names are lowercase strings (e.g. `claude`, `grok`, `factory`).
- The system does **not** hardcode a closed list of agent names.
- The publishing script will emit a warning when it encounters an unknown agent name, but will not fail.

This design makes it easy to add support for new agents in the future.

---

## 5. Scope and Nesting

- Markup can wrap blocks, sections, paragraphs, lists, or code blocks.
- Nesting is technically allowed but should be avoided when possible for readability.
- The inner-most block takes precedence when evaluating inclusion.

---

## 6. Examples

### Basic Claude-only section

```markdown
## Worktree Handling

<!-- agent:include claude -->
When you exit a worktree session, Claude Code will ask whether to keep or remove the worktree.
<!-- /agent:include claude -->

Regular guidance that applies to everyone goes here.
```

### Hiding content from Factory

```markdown
<!-- agent:exclude factory -->
Some advanced memory introspection features are only available in Claude and Grok.
<!-- /agent:exclude factory -->
```

### Comment with explanation

```markdown
<!-- Note: The following behavior differs significantly between Claude and other agents -->
<!-- agent:include claude -->
...
<!-- /agent:include claude -->
```

---

## 7. Mechanical Publishing Rules

The thin publishing script must:

1. Parse all `<!-- agent:include ... -->` and `<!-- agent:exclude ... -->` blocks. Tags are
   directives only when they start a line (leading whitespace allowed); a tag mentioned
   mid-line or inside backticks is prose, not a directive.
2. For each target agent, decide whether a block should be kept or removed according to the semantics above.
3. Strip **all** HTML comments (`<!-- ... -->`) from the final output — including multi-line
   comments — while preserving any non-comment text on the same line. Comment literals inside
   backtick code spans are kept.
4. Publish fenced code blocks (``` or ~~~) verbatim: no tag parsing and no comment stripping
   inside a fence (fenced tags are documentation examples; fenced comments are content).
   Include/exclude region filtering still applies to fenced lines.
5. Warn (but not fail) on unknown agent names.

---

## 8. Integration with `skills:import`

The `skills:import` skill is responsible for:

- Detecting agent-specific patterns in incoming skills.
- Working with the user to decide how to handle them.
- Inserting the appropriate `include` / `exclude` blocks (and optional explanatory comments) into the canonical source.

The markup is the primary mechanism the import skill uses to make content portable across agents.

---

## 9. Future Considerations

- We may later add support for more advanced expressions (e.g. versioned agent names) if needed.
- The current design deliberately stays minimal to match the project’s emphasis on elegance and simplicity.

---

**This document is the authoritative specification for the Embedded Markup used in the agent-tools canonical skill corpus.**