# Easy to Reference ID

> Use a meaningful prefix-number schema for issue IDs (like DTD-123) so they are easy to remember and reference in conversation.

**Category**: Design System
**Source**: [detail.design](https://detail.design/detail/easy-to-reference-id)

## Why It Matters

Identifiers like UUIDs or auto-incrementing integers are machine-friendly but human-hostile. A prefix-number schema (e.g., DTD-123 for a "Detail" project) combines organizational context with memorable numbering. Team members can reference "DTD-123" in conversation, chat, or documentation and everyone knows exactly which item is meant.

## How to Apply

- Structure IDs as: `[PROJECT_PREFIX]-[INCREMENT]` (e.g., DTD-123, ENG-456).
- Keep prefixes short (2-4 characters) and meaningful (derived from project or team name).
- Use incrementing numbers for scannability and natural ordering.
- Display these IDs prominently in the UI alongside titles.
- Support copy-to-clipboard on click for easy sharing.
- Make IDs searchable and linkable (e.g., typing "DTD-123" in search finds the item).

## Code Example

```javascript
function generateIssueId(projectPrefix, counter) {
  return `${projectPrefix}-${counter}`;
}

// Usage
const issueId = generateIssueId('DTD', 123); // "DTD-123"
```

## Audit Checklist

- [ ] Do entities use human-friendly ID schemas (prefix-number) rather than UUIDs?
- [ ] Are IDs prominently displayed and easy to copy?
- [ ] Can IDs be used in search to find the corresponding item?
- [ ] Are prefixes short, meaningful, and derived from project context?

## Media Reference

- Source: Linear

---
*From [detail.design](https://detail.design) by Rene Wang*
