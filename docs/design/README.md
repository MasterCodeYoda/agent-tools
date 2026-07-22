# Design documents

Committed home for **durable** design documents — designs worth keeping after the work
ships (system designs, harness architectures, cross-cutting proposals).

The rule this directory exists to enforce: **anything a committed file cites must itself
be committed.** `planning/` is transient per-item work product — it is gitignored, may be
purged by `/workflow:maintain` (prune job) at any time, and must never be referenced by committed docs,
skills, or READMEs. When a design produced under `planning/` turns out to be durable,
promote it here (rewritten for a reader, not a work log) before citing it.

The doc-integrity linter (`tools/doc_lint.py`, enforced in CI) fails on committed links
into `planning/`.
