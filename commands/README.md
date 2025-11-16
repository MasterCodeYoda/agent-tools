# Claude Commands

This directory contains custom commands for Claude to help with common development tasks.

## Available Commands

### /commit
**Purpose**: Create a conventional commit with proper formatting

**Usage**: Type `/commit` when you want to commit changes

**What it does**:
- Reviews current changes with `git status` and `git diff`
- Creates properly formatted conventional commits
- Includes Linear issue references when applicable
- Ensures code quality before committing

### /fix.quality
**Purpose**: Fix all code quality issues to achieve zero warnings

**Usage**: Type `/fix.quality` when quality checks are failing

**What it does**:
- Runs comprehensive quality checks
- Auto-fixes what's possible
- Provides guidance for manual fixes
- Ensures zero tolerance quality standards

### /spec.plan
**Purpose**: Plan feature implementation using vertical slicing

**Usage**: Type `/spec.plan` when starting a new Linear issue

**What it does**:
- Analyzes Linear issue requirements
- Creates vertical slice plan through all layers
- Breaks down into manageable tasks
- Documents technical decisions
- Updates Linear with plan details

### /spec.implement
**Purpose**: Implement features using vertical slicing strategy

**Usage**: Type `/spec.implement` after planning or for simple features

**What it does**:
- Implements complete vertical slice
- Follows bottom-up implementation (domain → framework)
- Runs tests at each layer
- Creates atomic, deployable features
- Updates Linear issue status

## Command Workflow

Typical workflow for a new feature:

1. **Plan the feature**:
   ```
   /spec.plan
   ```
   Creates implementation plan for Linear issue

2. **Implement the feature**:
   ```
   /spec.implement
   ```
   Builds vertical slice with tests

3. **Fix any quality issues**:
   ```
   /fix.quality
   ```
   Ensures zero warnings/errors

4. **Commit the changes**:
   ```
   /commit
   ```
   Creates conventional commit with Linear reference

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

## Integration with Linear

Commands that work with Linear:
- `/spec.plan` - Creates planning documents linked to Linear issues
- `/spec.implement` - Updates Linear status during implementation
- `/commit` - Includes Linear issue IDs in commit messages

Linear issue format: `LIN-123` (example)

## Best Practices

1. **Use commands consistently** - They encode team standards
2. **Keep Linear updated** - Commands help maintain visibility
3. **Follow vertical slicing** - Build complete features, not layers
4. **Maintain quality** - Zero tolerance for warnings/errors
5. **Document decisions** - Future you will thank present you