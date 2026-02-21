---
name: qa
description: QA skills for testing workflows — visual inspection tools and spec-driven regression testing
---

# QA Skills

Umbrella skill for quality assurance workflows. Routes to specialized sub-skills based on context.

## Sub-Skills

### @qa-tools — Visual Inspection Tools
Tools for inspecting visual artifacts during QA workflows: video frame extraction, screenshot analysis, and visual regression documentation.

**Use when**: You need to analyze screen recordings, extract frames from videos, or build visual evidence for bug reports.

### @qa-sentinel — Spec-Driven QA Testing
Methodology and tooling for spec-driven regression and UAT testing. Uses structured markdown specs as test definitions, driven by Claude via browser automation (Chrome DevTools MCP).

**Use when**: You need to define, discover, execute, or report on structured test specifications for a web application.

## Routing

- If the task involves **video frames, screenshots, or visual artifacts** → use `@qa-tools`
- If the task involves **test specs, regression testing, coverage tracking, or QA execution** → use `@qa-sentinel`
- If unsure, describe your QA need and this skill will route you
