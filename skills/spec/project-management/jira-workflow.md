# Jira Workflow Integration

This guide provides specific instructions for integrating vertical slicing with Atlassian Jira.

## Jira Overview

Jira is a comprehensive issue and project tracking tool widely used in enterprise environments, offering customizable workflows and extensive integration capabilities.

## Issue Structure in Jira

### Issue Key Format
```
PROJ-456
├─ PROJ: Project key (customizable)
└─ 456: Sequential issue number
```

### Common Project Keys
- `FEAT` - Features
- `BUG` - Bug fixes
- `TASK` - Tasks
- `US` - User Stories
- `TECH` - Technical tasks

### Issue Types
- **Story**: User-facing functionality
- **Task**: Technical work
- **Bug**: Defect fixes
- **Epic**: Large features
- **Sub-task**: Part of larger issue

## Vertical Slicing with Jira

### Step 1: Issue Analysis

When starting a vertical slice with a Jira ticket:

```markdown
## Jira Ticket: PROJ-456
**Type**: Story
**Summary**: [Issue summary from Jira]
**Status**: To Do → In Progress
**Priority**: [Highest/High/Medium/Low/Lowest]
**Story Points**: [Points if using Scrum]

### Description
[Copy from Jira description]

### Acceptance Criteria
[Copy from Jira AC field]

### Definition of Done
[Team's DoD from Jira]
```

### Step 2: Planning Documentation

Create planning in Jira or external doc:

#### Option A: Jira Description
Add to ticket description:
```markdown
## Vertical Slice Plan

### Domain Layer
- Task entity with validation
- Business rules

### Application Layer
- CreateTaskUseCase
- Request/Response DTOs

### Infrastructure Layer
- TaskRepository implementation
- Database schema

### API Layer
- POST /tasks endpoint
- Input validation

### Testing Strategy
- Unit tests per layer
- Integration tests
- E2E test
```

#### Option B: Confluence Page
Create linked Confluence page:
1. Click "Link" → "Confluence page"
2. Create page with plan
3. Link back to Jira ticket

### Step 3: Status Management

#### Typical Jira Workflow

| Status | When to Use | Actions |
|--------|------------|---------|
| **To Do** | Ready to start | Review requirements |
| **In Progress** | Actively working | Log work daily |
| **Code Review** | PR created | Link pull request |
| **In Testing** | Tests running | Run test suites |
| **Ready for Deploy** | Tests passed | Awaiting deployment |
| **Done** | Deployed | Resolve issue |
| **Closed** | Verified in prod | Close issue |

#### Transition Using MCP

Using MCP tools (if available):
```javascript
// Move to In Progress
mcp__jira__transitionIssue(
  issueKey: "PROJ-456",
  transition: "Start Progress"
)

// Add work log
mcp__jira__logWork(
  issueKey: "PROJ-456",
  timeSpent: "2h",
  comment: "Completed domain layer"
)

// Add comment
mcp__jira__addComment(
  issueKey: "PROJ-456",
  body: "Domain and infrastructure layers complete"
)
```

Manual updates:
1. Open Jira ticket
2. Click "Workflow" or status button
3. Select transition
4. Add comment/log work
5. Click transition button

### Step 4: Commit Integration

#### Commit Message Format

```bash
# Feature commit
git commit -m "feat(tasks): implement create task endpoint [PROJ-456]

- Add Task domain entity
- Implement CreateTaskUseCase
- Add POST /tasks endpoint
- Include test coverage

Resolves: PROJ-456"

# Fix commit
git commit -m "fix(tasks): resolve validation error [PROJ-456]

Fixes validation issue in task creation

See: PROJ-456"
```

#### Smart Commits (if enabled)

```bash
# Transition and comment
git commit -m "PROJ-456 #in-progress Added domain layer
PROJ-456 #time 2h #comment Domain implementation complete"

# Resolve with time tracking
git commit -m "PROJ-456 #resolve #time 4h Feature complete and tested"
```

### Step 5: Pull Request Integration

#### PR Title Format
```
PROJ-456: Implement task creation vertical slice
```

#### PR Description for Jira
```markdown
## Summary
Implements vertical slice for task creation feature.

## Jira Ticket
[PROJ-456](https://company.atlassian.net/browse/PROJ-456)

## Implementation
- **Domain**: Task entity with validation
- **Application**: CreateTaskUseCase
- **Infrastructure**: TaskRepository with PostgreSQL
- **API**: POST /tasks endpoint

## Testing
- Unit tests: ✅ (85% coverage)
- Integration tests: ✅
- E2E tests: ✅

## Checklist
- [x] Jira AC met
- [x] Tests passing
- [x] Documentation updated
- [x] Ready for review
```

### Step 6: Time Tracking

#### Log Work in Jira

```markdown
## Work Log Entry
**Date**: 2024-01-15
**Time Spent**: 6h
**Remaining**: 2h

**Work Description**:
- Domain layer: 1.5h
- Infrastructure: 2h
- Application: 1.5h
- API & Testing: 1h
```

Using Jira UI:
1. Open ticket
2. Click "More" → "Log work"
3. Enter time (e.g., "6h")
4. Adjust remaining estimate
5. Add work description
6. Submit

### Step 7: Sprint Management

#### Adding to Sprint

For Scrum teams:
```markdown
## Sprint 23 Planning
**Sprint Goal**: Complete user management

### Vertical Slices:
1. PROJ-456: Create user (5 points)
2. PROJ-457: Update user (3 points)
3. PROJ-458: Delete user (2 points)
4. PROJ-459: List users (3 points)
```

In Jira:
1. Open backlog
2. Drag ticket to sprint
3. Ensure points estimated
4. Check capacity

#### Sprint Board Updates

During sprint:
- Move cards through columns
- Update remaining time daily
- Flag blockers
- Link PRs and commits

## Jira-Specific Features

### Components

Organize vertical slices by component:

| Component | Description |
|-----------|-------------|
| `domain` | Domain layer changes |
| `api` | API endpoints |
| `database` | Schema changes |
| `ui` | Frontend changes |
| `infrastructure` | System components |

### Labels

Useful labels for vertical slicing:

```
vertical-slice
ready-for-dev
in-review
needs-testing
tech-debt
```

### Fix Version

Track deployment targets:

```markdown
## Fix Versions
- v1.0.0: MVP release
  - PROJ-456: Create task ✅
  - PROJ-457: List tasks ✅
- v1.1.0: Enhancements
  - PROJ-458: Update task
  - PROJ-459: Delete task
```

### Epics and Stories

Structure for vertical slicing:

```
Epic: User Management System
├─ Story: PROJ-456: Create user
│   ├─ Sub-task: Domain implementation
│   ├─ Sub-task: API implementation
│   └─ Sub-task: Testing
├─ Story: PROJ-457: View user details
└─ Story: PROJ-458: Update user
```

## Jira Automation

### Useful Automation Rules

1. **Auto-transition on PR**
   - Trigger: Pull request created
   - Condition: Issue in "In Progress"
   - Action: Transition to "Code Review"

2. **Auto-close on merge**
   - Trigger: Pull request merged
   - Condition: Issue in "Code Review"
   - Action: Transition to "Done"

3. **Stale issue warning**
   - Trigger: Issue in "In Progress" >3 days
   - Action: Add comment asking for update

### JQL Queries for Vertical Slices

```sql
-- Current sprint vertical slices
project = PROJ AND sprint in openSprints() AND labels = "vertical-slice"

-- My in-progress slices
assignee = currentUser() AND status = "In Progress" AND type = Story

-- Completed slices this week
project = PROJ AND resolved >= -1w AND labels = "vertical-slice"

-- Blocked slices
project = PROJ AND status = "In Progress" AND flagged = Impediment
```

## Integration with Development Tools

### Bitbucket/GitHub Integration

Link commits and PRs:
1. Include ticket ID in commit
2. Jira automatically links
3. See development panel in ticket

### IDE Integration

Jira plugins for IDEs:
- IntelliJ: "Atlassian Connector"
- VS Code: "Jira and Bitbucket"
- Allows viewing/updating from IDE

### CI/CD Integration

Jenkins/GitLab CI example:
```yaml
# .gitlab-ci.yml
deploy:
  script:
    - deploy_to_production
  after_script:
    - 'curl -X POST ${JIRA_URL}/rest/api/2/issue/${CI_COMMIT_MESSAGE}/transitions
          -d ''{"transition":{"id":"31"}}'' # Done transition'
```

## Reporting in Jira

### Velocity Chart

Track vertical slice completion:
- Points completed per sprint
- Average velocity
- Predictability

### Burndown Chart

Monitor sprint progress:
- Ideal vs actual
- Daily progress
- Remaining work

### Custom Dashboard

Create VS dashboard:
```
Widgets:
- Filter Results: Current sprint slices
- Pie Chart: Slices by status
- Activity Stream: Recent updates
- Average Age Chart: Cycle time
```

## Best Practices for Jira + Vertical Slicing

1. **One Ticket = One Slice**: Keep tickets focused
2. **Use Sub-tasks Sparingly**: Only for layer tracking if needed
3. **Consistent Workflow**: Same status flow for all slices
4. **Regular Updates**: Update daily during standup
5. **Link Everything**: Commits, PRs, docs, dependencies
6. **Time Tracking**: Helps improve estimates
7. **Automation**: Reduce manual status updates

## Common Jira Patterns

### Pattern 1: Story Point Sizing
```
1 point = 2-4 hours (XS slice)
2 points = 4-8 hours (S slice)
3 points = 1-2 days (M slice)
5 points = 2-3 days (L slice)
8 points = Too big, split it!
```

### Pattern 2: Definition of Ready
```markdown
## Ready for Development
- [ ] User story clear
- [ ] Acceptance criteria defined
- [ ] Vertical slice planned
- [ ] Dependencies identified
- [ ] Estimated
```

### Pattern 3: Definition of Done
```markdown
## Slice Complete When
- [ ] Code complete
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] PO accepted
```

## Troubleshooting

### Issue: Complex Workflows
**Solution**: Simplify to essential statuses only

### Issue: Too Many Fields
**Solution**: Create "Vertical Slice" issue type with minimal fields

### Issue: Slow Board Performance
**Solution**: Limit board to current sprint only

### Issue: Lost in Sub-tasks
**Solution**: Keep everything in main story ticket

## Remember

- Jira is highly customizable - adapt to your workflow
- Use JQL to create useful filters
- Leverage automation to reduce overhead
- Keep tickets focused on single vertical slices
- Regular updates maintain visibility
- Integration with dev tools provides traceability