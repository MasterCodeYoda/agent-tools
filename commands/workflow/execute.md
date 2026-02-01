---
name: workflow:execute
description: Session-based work execution with progress tracking and knowledge capture
argument-hint: "[planning directory, plan file, 'continue', or session summary text]"
---

# Session-Based Work Execution

Execute work plans while maintaining session continuity and capturing knowledge.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine session mode:

| Input Pattern           | Interpretation                                        |
|-------------------------|-------------------------------------------------------|
| `./planning/<project>/` | Start/continue project from planning subdirectory     |
| `./planning/` or empty  | Auto-detect from `./planning/*.md` or `./planning/*/` |
| `*.md` file path        | Execute specific plan file                            |
| `continue`              | Resume last active session                            |
| `LIN-[0-9]+`            | Direct execution from Linear issue                    |
| `[A-Z]+-[0-9]+`         | Direct execution from Jira ticket                     |
| Text summary            | Steering input for next session                       |

## Direct Issue Execution

For simple tasks that don't require detailed planning documents, execute directly from an issue tracker item.

### When to Use Direct Execution

- Bug fixes with clear reproduction steps
- Small enhancements with well-defined scope
- Tasks where the issue description IS the plan
- Quick iterations where planning overhead isn't justified

### Direct Execution Flow

```
1. Fetch issue details (via MCP or API)
2. Extract:
   - Title → task subject
   - Description → requirements
   - Acceptance criteria (if present) → quality gates
3. Create minimal session state (in-memory or temporary)
4. Display issue context to user:
      ```markdown
      ## Direct Execution: [ISSUE-ID]
      **Title**: [issue title]
      **Description**: [issue description]
      **Status**: [current status]
      ```
5. Confirm with user before proceeding
6. Execute using standard Execution Loop (below)
7. On completion:
    - Commit with issue reference
    - Update issue status to Done
    - Offer to create planning docs if scope expanded

```

### Escalation to Full Planning

If during direct execution the task proves more complex than expected:

1. Pause execution
2. Suggest running `/workflow:plan [ISSUE-ID]`
3. Create proper planning documents
4. Resume with full session tracking

## Session Initialization

### 1. Locate Planning Documents

Check for planning documentation in order of precedence:

```bash
# First: Check for project subdirectories with session state
ls ./planning/*/session-state.md 2>/dev/null

# Second: Check for files directly in ./planning/
ls ./planning/*.md 2>/dev/null
```

**Supported structures:**

```
# Structure A: Project subdirectory (multi-project)
./planning/
├── project-a/
│   ├── requirements.md
│   ├── implementation-plan.md
│   └── session-state.md
└── project-b/
    └── ...

# Structure B: Direct files (single project)
./planning/
├── requirements.md
├── implementation-plan.md
└── session-state.md
```

### 2. Load Session State

**If session-state.md exists** (in subfolder or directly in ./planning/):

- Read current session context
- Display progress summary
- Confirm task continuation

**If no session state but planning docs exist:**

- Read @planning/*.md for context (requirements, implementation plan)
- Create new session-state.md
- Initialize from implementation-plan.md
- Set session_count: 1

**If multiple project subdirectories exist:**

- List available projects
- Ask user which to continue

### 3. Context Review

Display context to user:

```markdown
## Session Context

**Project**: [project-name]
**Session**: #[N] of work
**Progress**: [X]/[Y] tasks ([%] complete)
**Current Focus**: [active area]
**Last Session**: [brief summary if exists]
```

### 4. Task Selection

Using the implementation plan and session state:

1. Identify next P1 task (must-have)
2. If all P1 complete, move to P2 tasks
3. If all P2 complete, move to P3 tasks
4. Consider user input for task steering
5. Evaluate task steps to identify parallel execution opportunties, and use sub-agents where feasible

Ask user to confirm task selection if unclear.

## Execution Loop

For detailed implementation guidance and quality checkpoints, reference @workflow-guide (quality checkpoints, layer
guidance)

### Task Execution Pattern

```
while (tasks remain):
  1. Mark task in_progress in TodoWrite
  2. Read relevant files from plan
  3. Look for existing patterns in codebase
  4. Implement following conventions
  5. Write tests for new functionality
  6. Run tests after changes
  7. Mark task completed in TodoWrite
  8. Update plan file ([ ] -> [x])
  9. Check for story/slice completion
  10. Check for session boundary
```

### Story/Slice Completion Checkpoint

**CRITICAL**: When implementing multi-story features (epics), commit each story independently:

```
For each story/slice in an epic:
1. Implement story end-to-end (all layers)
2. Run full test suite
3. Mark task completed in TodoWrite
4. Commit with message: `feat(scope): description (ISSUE-ID)`
5. Update PM tool (Linear/Jira) - mark story Done
6. Move to next story
```

**Why This Matters**:

- Each commit is a safe checkpoint to return to
- PM tools show real progress, not "everything in progress"
- Git history enables bisect and blame
- Risk of work loss is minimized

**Anti-Pattern to Avoid**:

```
❌ Work on all 4 stories, commit once at the end
   - No incremental progress visible
   - Risk of losing significant work
   - Hard to review and debug

✅ Complete story → commit → update PM → next story
   - Clear progress tracking
   - Easy rollback if needed
   - Better collaboration
```

### Quality Gates

Before marking a task complete:

- [ ] Implementation matches plan requirements
- [ ] Tests pass for new functionality
- [ ] No linting/type errors introduced
- [ ] Code follows existing patterns
- [ ] Changes are focused and atomic

Run quality checks based on project type:

```bash
# Detect and run appropriate checks
# Python: pytest, mypy, ruff
# TypeScript: npm test, tsc, eslint
# Rails: bin/rails test, rubocop
```

### Progress Tracking

Keep the plan file updated as you work:

```markdown
### P1 Tasks

- [x] Create domain entity  <- completed
- [ ] Implement use case    <- next
- [ ] Add API endpoint
```

Update session-state.md after each significant milestone.

## Session Boundaries

### Detecting Boundary Conditions

Check for session end when:

- Major task group completed (all P1s)
- Significant milestone reached
- User indicates session ending
- Context becoming stale

### Session Handoff Protocol

When reaching a session boundary:

#### 1. Update Session State

Write to `./planning/<project>/session-state.md`:

```yaml
---
project: [project-name]
session_count: [N]
status: in_progress
progress:
  total_tasks: [X]
  completed: [Y]
  percent: [Z%]
current_layer: [domain|infrastructure|application|framework]
branch: <type>/<issue-key or description>
last_updated: [timestamp]
---

## Current Focus
[What's being worked on]

## Last Session Summary
[Detailed summary for handoff - what was done, key decisions, blockers]

## Recommended Next Steps
1. [Next priority task]
2. [Following task]
3. [Future consideration]

## Session History
### Session N - [date]
- Completed: [list]
- Decisions: [list]
- Blockers: [list]
```

#### 2. Git Commit

Commit work with clear message:

```bash
git add .
git status
git commit -m "$(cat <<'EOF'
feat(area): description of progress

- Task 1 completed
- Task 2 completed
- Progress: X/Y tasks

Session: #N for [project-name]

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

#### 3. Compound Prompt

After saving session state, prompt for knowledge capture:

```markdown
## Session Learnings

This session you worked on:
[Summary of work]

**Discoveries or solutions worth documenting?**

1. Yes - run /workflow:compound with context
2. No - continue to handoff
3. Note for later - add to session notes
```

If user selects "Yes", invoke compound with pre-filled context:

```
/workflow:compound "[brief context of what was solved]"
```

#### 4. Generate Handoff Summary

Provide complete handoff for next session:

```markdown
## Session #N Complete

### What Was Done

- [Detailed list of accomplishments]

### Key Decisions Made

- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Current State

- Branch: `feat/ISSUE-123` or `fix/ISSUE-123`
- Tests: [passing/failing]
- Progress: [X%]

### Recommended Next Steps

1. **Next Priority**: [specific task]
2. **Consider**: [upcoming decision point]
3. **Watch For**: [potential blockers]

### Files Modified

- `path/to/file1.py` - [what changed]
- `path/to/file2.py` - [what changed]

### To Resume

```bash
/workflow:execute ./planning/[project]/
# Or with this summary:
/workflow:execute "[paste this summary for context]"
```

```

## Error Recovery

### If Tests Fail
1. Fix immediately before proceeding
2. If complex, create TODO in session state
3. Do not move to next task with failing tests

### If Blocked
1. Document blocker in session state
2. Create task for resolution
3. Proceed with parallel work if possible
4. Escalate to user if blocking critical path

### If Lost Context
1. Read session-state.md for orientation
2. Review git log for recent changes
3. Read implementation-plan.md for overall scope
4. Ask user for clarification if needed

## Key Principles

### Ship Complete Work
- Finish tasks before moving on
- Don't leave features 80% done
- A shipped feature beats a perfect unfinished one

### Maintain Continuity
- Session state is source of truth
- Update documentation as you work
- Enable seamless handoff between sessions

### Build Knowledge
- Compound captures learnings
- Each problem solved helps future work
- Documentation is investment, not overhead

### Quality Built In
- Follow existing patterns
- Write tests as you go
- Run quality checks continuously

## Definition of Done (Per Task)

- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Plan checkbox updated
- [ ] Session state reflects progress
- [ ] No introduced regressions
- [ ] Committed (if completing a story/slice)
- [ ] PM tool updated (story marked Done)

## Definition of Done (Per Session)

- [ ] All targeted tasks complete or documented
- [ ] Session state updated
- [ ] Work committed
- [ ] Compound prompt offered
- [ ] Handoff summary provided
