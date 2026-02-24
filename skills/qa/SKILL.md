---
name: qa
description: QA skills for testing workflows — visual inspection tools and NL spec authoring for Playwright Test Agents
---

# QA Skills

Umbrella skill for quality assurance workflows. Routes to specialized sub-skills based on context.

## Sub-Skills

### @qa-tools — Visual Inspection Tools
Tools for inspecting visual artifacts during QA workflows: video frame extraction, screenshot analysis, and visual regression documentation.

**Use when**: You need to analyze screen recordings, extract frames from videos, or build visual evidence for bug reports.

### @qa-sentinel — NL Spec Authoring & Audit
Methodology and tooling for authoring Natural Language test specifications and auditing test coverage. Claude writes structured NL specs; Playwright Test Agents generate and execute `.spec.ts` tests deterministically.

**Use when**: You need to author test specifications, set up Playwright Test Agents integration, or audit drift between specs, tests, and app behavior.

## Routing

- If the task involves **video frames, screenshots, or visual artifacts** → use `@qa-tools`
- If the task involves **test specs, NL spec authoring, audit, coverage tracking, or Playwright Test Agents** → use `@qa-sentinel`
- If unsure, describe your QA need and this skill will route you
