# Migration Notice: Spec Commands

## Deprecated Commands

The following commands have been deprecated and their functionality has been migrated to the enhanced `spec` skill:

- `/spec.plan` - Planning features with vertical slicing
- `/spec.implement` - Implementing features with vertical slicing

## Migration Path

These commands have been archived on: **2024-11-18**

### Why the Change?

The spec commands have been converted to an enhanced skill to provide:
- Better flexibility with project management tools (Linear, Jira, or manual)
- More comprehensive guidance combining philosophy with practical workflows
- Language-agnostic templates and patterns
- Modular documentation structure
- Optional PM tool integration rather than Linear-specific

### How to Use the New Skill

Instead of using commands, activate the spec skill:

```
Skill: spec
```

The skill now includes:
- Complete planning workflows (previously `/spec.plan`)
- Implementation workflows (previously `/spec.implement`)
- Project management integration (Linear, Jira, or manual)
- Extensive templates and examples
- Quality checkpoints and best practices

### Feature Mapping

| Old Command | New Skill Section |
|-------------|------------------|
| `/spec.plan` Step 1-8 | Planning Workflow |
| Vertical slice template | spec/planning/templates.md |
| Task breakdown | spec/planning/task-breakdown.md |
| Technical decisions | spec/planning/technical-decisions.md |
| `/spec.implement` Step 1-8 | Implementation Workflow |
| Bottom-up approach | spec/implementation/bottom-up-workflow.md |
| Layer templates | spec/implementation/layer-templates.md |
| Quality checks | spec/implementation/quality-checkpoints.md |
| Linear integration | spec/project-management/linear-workflow.md |
| N/A (new) | spec/project-management/jira-workflow.md |
| N/A (new) | spec/project-management/manual-workflow.md |

### Configuration

The new skill supports configuration via `.claude/settings.json`:

```json
{
  "preferences": {
    "project_management": {
      "tool": "manual",  // "linear", "jira", or "manual"
      "update_on_commit": true,
      "include_time_tracking": false
    }
  }
}
```

### Benefits of the Migration

1. **Tool Independence**: Works with any PM tool, not just Linear
2. **Better Organization**: Modular structure with focused documents
3. **More Examples**: Comprehensive planning and implementation examples
4. **Language Agnostic**: Patterns work for any programming language
5. **Extensible**: Easy to add support for more PM tools

### Temporary Backward Compatibility

For a transition period, you can still reference these archived commands, but they will show a deprecation notice pointing to the spec skill.

### Questions or Issues?

If you encounter any issues with the migration or have questions about using the new skill, please refer to:
- Main skill: `skills/spec/SKILL.md`
- Integration guide: `skills/spec/project-management/integration-guide.md`

## Archived Files

- `spec.plan.md` - Original planning command
- `spec.implement.md` - Original implementation command

These files are preserved for reference but should not be used for new work.