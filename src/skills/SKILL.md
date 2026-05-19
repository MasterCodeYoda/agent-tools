---
name: skills
description: Meta-skill responsible for the health, growth, and portability of the canonical skill corpus. Provides capabilities for importing skills from other agent platforms and evolving existing skills over time.
user-invocable: true
publish-target: project
---

# Skills (Meta-Skill)

This is the meta-skill for the overall skill system. Its purpose is to maintain and improve the quality and portability of the canonical skill library.

## Purpose

- Ensure new skills can be effectively absorbed from any supported agent platform.
- Continuously improve the structure, clarity, and maintainability of existing skills.
- Maintain accurate, up-to-date knowledge about the capabilities and quirks of each target agent.

## Sub-Capabilities

| Capability       | Command          | Description |
|------------------|------------------|-----------|
| Import           | `/skills:import` | Import and adapt skills written for other agents into the canonical format. |
| Evolve           | `/skills:evolve` | Analyze and iteratively improve skills already in the corpus. |

## Structure

- `import/` — Handles the import and canonicalization of external skills.
- `evolve/` — Handles ongoing analysis and improvement of existing skills.
- `references/` — Supporting reference material, including agent capability quick-references and the embedded markup specification.

## Philosophy

The value of this system lies in the quality and portability of the skills themselves, not in the complexity of the tooling around them. The `skills` meta-skill exists to keep the corpus healthy, consistent, and easy to contribute to over time.