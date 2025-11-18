# Claude Commands

This directory contains custom commands for Claude to help with common development tasks.

## Available Commands

### /commit
**Purpose**: Create a conventional commit with proper formatting

**Usage**: Type `/commit` when you want to commit changes

**What it does**:
- Reviews current changes with `git status` and `git diff`
- Creates properly formatted conventional commits
- Includes issue references when applicable
- Ensures code quality before committing

### /fix.quality
**Purpose**: Fix all code quality issues to achieve zero warnings

**Usage**: Type `/fix.quality` when quality checks are failing

**What it does**:
- Runs comprehensive quality checks
- Auto-fixes what's possible
- Provides guidance for manual fixes
- Ensures zero tolerance quality standards

## Migrated to Skills

The following commands have been enhanced and migrated to the `spec` skill for better flexibility and comprehensive guidance:

### ~~spec.plan~~ → Use `spec` skill
**Previous Purpose**: Plan feature implementation using vertical slicing

**Migration**: Now part of the enhanced `spec` skill with:
- Support for Linear, Jira, or manual project management
- Language-agnostic templates
- Comprehensive planning workflows
- See: `skills/spec/planning/`

### ~~spec.implement~~ → Use `spec` skill
**Previous Purpose**: Implement features using vertical slicing strategy

**Migration**: Now part of the enhanced `spec` skill with:
- Bottom-up implementation guidance
- Layer-by-layer templates
- Quality checkpoints
- See: `skills/spec/implementation/`

**To use the new skill**: Simply invoke the `spec` skill instead of the commands. It provides all the previous functionality plus additional features and flexibility.

## Command Workflow

Typical workflow for a new feature:

1. **Plan the feature** (use `spec` skill):
   - Comprehensive planning templates
   - Task breakdown and prioritization
   - Technical decision documentation

2. **Implement the feature** (use `spec` skill):
   - Bottom-up implementation workflow
   - Layer-by-layer guidance
   - Quality checkpoints

3. **Fix any quality issues**:
   ```
   /fix.quality
   ```
   Ensures zero warnings/errors

4. **Commit the changes**:
   ```
   /commit
   ```
   Creates conventional commit with issue reference

## Creating New Commands

To add a new command:

1. Create a markdown file in this directory (e.g., `new-command.md`)
2. Start with a clear heading: `# /new-command - Purpose`
3. Include sections:
   - Instructions (step-by-step guide)
   - Examples (concrete usage examples)
   - Checklist (verification steps)
4. Document in this README

## Command Guidelines

When creating commands:
- Keep them focused on a single task
- Provide clear, actionable steps
- Include examples where helpful
- Reference project standards (AGENTS.md)
- Integrate with Linear when applicable
- Maintain zero-tolerance quality standards

## Integration with Project Management Tools

The `spec` skill now supports multiple PM tools:
- **Linear**: Issue format `LIN-123`
- **Jira**: Ticket format `PROJ-456`
- **Manual/Other**: Use your tool's format

The `/commit` command works with any issue reference format in commit messages.

Configure your PM tool preference in `.claude/settings.json` - see the spec skill documentation for details.

## Best Practices

1. **Use commands consistently** - They encode team standards
2. **Keep Linear updated** - Commands help maintain visibility
3. **Follow vertical slicing** - Build complete features, not layers
4. **Maintain quality** - Zero tolerance for warnings/errors
5. **Document decisions** - Future you will thank present you