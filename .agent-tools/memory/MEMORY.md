# Project memory index

Agent working knowledge for this repo (patterns, gotchas, lessons, debugging solutions).
Maintained by `/workflow:compound`. Not a substitute for ADRs, CONTRIBUTING, or Codex/domain docs.

## Entries

- [Publisher strips HTML comments](entries/publisher-strips-html-comments.md) — comments stripped outside fenced code only; fence or backtick literal markers a skill must emit
- [Docs-as-code needs code-grade gates](entries/docs-as-code-needs-code-grade-gates.md) — reference linter + golden tests in CI catch what manual audits miss; extend fixtures with every new behavior
- [Content-move refactors need conservation review](entries/content-move-refactors-need-conservation-review.md) — move verbatim with byte-diff manifests; review with conservation + executability lenses; namespace pointers
- [Cross-agent delegation needs self-contained baseline](entries/cross-agent-delegation-self-contained-baseline.md) — prefer-delegate only as agent-gated enrichment; real logic runs unmarked on every agent
- [Specs go in planning/](entries/specs-go-in-planning.md) — working specs in transient `planning/`; durable designs promote to `docs/design/`; committed files never cite planning/ paths
- [No push or ahead-of-main reminders](entries/no-push-or-ahead-of-main-reminders.md) — never prompt push or report commits-ahead-of-origin

## Solutions

Debugging post-mortems live under `solutions/<category>/`. Search by `symptoms` / `tags` in
frontmatter; browse by category. Do not enumerate every solution here.
