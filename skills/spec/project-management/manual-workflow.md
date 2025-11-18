# Manual Workflow (Default)

This guide provides a flexible, tool-agnostic approach for teams using custom project management tools or preferring manual tracking.

## Overview

The manual workflow is the default option that works with any project management system, including:
- GitHub Issues
- GitLab Issues
- Azure DevOps
- Trello
- Asana
- Monday.com
- Notion
- Simple spreadsheets
- Physical boards

## Universal Principles

Regardless of your tool, these principles apply:

1. **One Work Item = One Vertical Slice**
2. **Clear Status Progression**
3. **Consistent References**
4. **Regular Updates**
5. **Linked Artifacts**

## Generic Work Item Structure

### Work Item Template

```markdown
## Work Item: [YOUR-ID-FORMAT]
**Title**: [Descriptive title]
**Type**: [Feature/Bug/Task]
**Priority**: [Your priority system]
**Status**: [Your status]
**Estimate**: [Your estimation unit]

### Description
[What needs to be done]

### Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

### Vertical Slice Plan
[Link to plan or embed here]
```

### Example Formats

Different tools use different ID formats:

| Tool | Format Example |
|------|----------------|
| GitHub | `#123` |
| GitLab | `!456` |
| Azure DevOps | `AB#789` |
| Trello | Card link |
| Custom | `TASK-2024-001` |

## Planning Phase

### Step 1: Document the Work

Create a planning document in your preferred location:

```markdown
# [ID]: [Feature Name]

## Work Item Details
- **Source**: [Your PM tool]
- **ID**: [Work item ID]
- **Priority**: [Priority level]
- **Estimate**: [Time/points]

## User Story
As a [user type], I want [capability] so that [benefit].

## Vertical Slice Breakdown
1. Domain Layer
   - [What entities/logic]
2. Application Layer
   - [What use cases]
3. Infrastructure Layer
   - [What persistence/integrations]
4. Framework Layer
   - [What endpoints/UI]

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Testing Strategy
[How you'll test each layer]
```

### Step 2: Link to Your Tool

Update your PM tool with planning info:

**Option A: Direct Update**
- Copy plan into ticket description
- Add as comment
- Attach as document

**Option B: Link Reference**
- Add link to planning doc
- Note: "Plan: [link]"
- Update status to "Planned"

## Implementation Phase

### Status Management

Define your status flow:

```markdown
## Standard Flow
Not Started → In Progress → Review → Testing → Done

## Custom Flow Example
Backlog → Planning → Development → QA → Deployed → Closed
```

### Daily Updates

Template for progress updates:

```markdown
## Daily Update: [Date]
**Status**: In Progress
**Completed Today**:
- ✅ Domain layer implementation
- ✅ Unit tests for domain

**Tomorrow**:
- Infrastructure layer
- Integration tests

**Blockers**: None
```

### Commit Integration

Include work item reference in commits:

```bash
# Generic format
git commit -m "type(scope): description [WORK-ITEM-ID]"

# Examples for different tools
git commit -m "feat(tasks): add create endpoint [#123]"        # GitHub
git commit -m "fix(auth): resolve timeout [!456]"              # GitLab
git commit -m "docs(api): update readme [AB#789]"              # Azure DevOps
git commit -m "refactor(db): optimize queries [TASK-2024-001]" # Custom
```

## Tracking Progress

### Simple Progress Tracker

```markdown
## Vertical Slice: Create User

### Layers Progress
- [x] Domain Layer (2h)
- [x] Infrastructure Layer (2h)
- [ ] Application Layer (est: 1.5h)
- [ ] API Layer (est: 1h)
- [ ] Testing (est: 1h)

**Total Progress**: 40% (4h of ~7.5h)
```

### Checklist Format

```markdown
## Implementation Checklist

### Planning
- [x] Requirements clear
- [x] Vertical slice planned
- [x] Tasks identified

### Development
- [x] Domain implementation
- [x] Domain tests
- [x] Infrastructure implementation
- [ ] Infrastructure tests
- [ ] Application implementation
- [ ] Application tests
- [ ] API implementation
- [ ] E2E tests

### Completion
- [ ] Code review
- [ ] Documentation updated
- [ ] Deployed
- [ ] Work item closed
```

## Documentation

### Where to Store

Choose based on your setup:

| Location | Best For |
|----------|----------|
| `docs/` folder | Version-controlled docs |
| Wiki | Team knowledge base |
| PM tool | Centralized tracking |
| Confluence | Enterprise teams |
| Notion | Flexible documentation |
| README | Simple projects |

### Documentation Template

```markdown
# Feature: [Name]
**Work Item**: [ID]
**Completed**: [Date]

## Summary
[What was implemented]

## Technical Decisions
[Key decisions made]

## Lessons Learned
[What went well/poorly]

## Future Improvements
[What could be enhanced]
```

## Time Tracking (Optional)

### Simple Time Log

```markdown
## Time Log: [Work Item ID]

| Date | Activity | Duration |
|------|----------|----------|
| 2024-01-15 | Planning | 1h |
| 2024-01-15 | Domain layer | 1.5h |
| 2024-01-16 | Infrastructure | 2h |
| 2024-01-16 | Application | 1.5h |
| 2024-01-17 | API & Testing | 2h |
| **Total** | | **8h** |

**Estimated**: 6h
**Actual**: 8h
**Variance**: +33%
```

### Effort Categories

Track where time goes:

```markdown
## Effort Breakdown
- Planning: 15%
- Coding: 50%
- Testing: 25%
- Review/Deploy: 10%
```

## Tool-Specific Adaptations

### GitHub Issues

```markdown
## GitHub-Specific
- Use issue templates
- Link PRs with "Closes #123"
- Use labels: `vertical-slice`, `in-progress`
- Milestones for grouping
- Projects for boards
```

### Trello

```markdown
## Trello-Specific
- Card = Vertical slice
- Lists = Status columns
- Labels = Categories
- Checklist = Implementation tasks
- Due dates = Deadlines
```

### Spreadsheet

```markdown
## Spreadsheet Columns
| ID | Title | Status | Domain | Infra | App | API | Tests | Notes |
|----|-------|--------|--------|-------|-----|-----|-------|-------|
| 001 | Create | In Prog | ✅ | ✅ | ⏳ | ⏳ | ⏳ | On track |
```

### Physical Board

```markdown
## Physical Board Setup
Columns: Backlog | In Progress | Review | Done

Sticky Notes:
- Color = Priority
- Top = Work item ID
- Middle = Description
- Bottom = Assignee

Daily: Move stickies, update status
```

## Metrics Without Tools

### Velocity Tracking

```markdown
## Sprint/Week Velocity

### Week 1
- Planned: 3 slices
- Completed: 2 slices
- Velocity: 67%

### Week 2
- Planned: 3 slices
- Completed: 3 slices
- Velocity: 100%

Average: 83.5%
```

### Quality Metrics

```markdown
## Quality Tracking

### Slice: Create User
- Tests Written: 15
- Tests Passing: 15
- Bugs Found: 1
- Rework Needed: No

### Slice: Update User
- Tests Written: 12
- Tests Passing: 11
- Bugs Found: 2
- Rework Needed: Yes (validation)
```

## Best Practices

### 1. Consistency is Key
- Use same format always
- Update regularly
- Follow your process

### 2. Keep It Simple
- Don't over-document
- Focus on value
- Automate what you can

### 3. Make It Visible
- Share progress
- Update stakeholders
- Celebrate completions

### 4. Learn and Adapt
- Track what works
- Adjust process
- Share learnings

## Common Patterns

### Pattern 1: Weekly Rhythm
```
Monday: Plan slice
Tuesday-Thursday: Implement
Friday: Review & deploy
```

### Pattern 2: Status Indicators
```
🔴 Blocked
🟡 In Progress
🟢 Complete
⏳ Waiting
✅ Done
```

### Pattern 3: Priority Matrix
```
Urgent + Important = P0 (Do now)
Not Urgent + Important = P1 (Schedule)
Urgent + Not Important = P2 (Delegate)
Not Urgent + Not Important = P3 (Later)
```

## Templates Collection

### Quick Planning Template
```markdown
**Slice**: [Name]
**ID**: [Work item]
**Estimate**: [Time]

Plan:
1. Domain: [What]
2. Infrastructure: [What]
3. Application: [What]
4. API/UI: [What]

GO/NO-GO: [Decision]
```

### Quick Status Template
```markdown
[ID] Status: [Status]
Done: [What's complete]
Next: [What's next]
Blockers: [Any issues]
ETA: [Completion estimate]
```

### Quick Retrospective Template
```markdown
**Slice**: [Name]
✅ Went Well: [What worked]
⚠️ Could Improve: [What didn't]
💡 Learned: [New knowledge]
```

## Remember

- The tool doesn't matter, the process does
- Consistency beats complexity
- Regular updates maintain momentum
- Simple tracking is better than none
- Adapt the process to your needs
- Focus on delivering value, not process