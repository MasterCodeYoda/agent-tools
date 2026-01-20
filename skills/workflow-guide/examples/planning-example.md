# Example: Planning User Registration

A complete walkthrough of planning a vertical slice for user registration.

## Work Item

**ID**: LIN-789
**Title**: Implement user registration
**Priority**: P0 (Critical)

## Requirements Document

### ./planning/user-registration/requirements.md

```markdown
# User Registration

## Overview
Allow new visitors to create accounts to access personalized features.

## User Story
As a new visitor, I want to register for an account so that I can access personalized features.

## Acceptance Criteria
- [ ] User can enter email and password
- [ ] Email validation is performed
- [ ] Password meets security requirements (8+ chars, complexity)
- [ ] Duplicate emails are rejected
- [ ] User receives confirmation email
- [ ] Account is inactive until email confirmed
- [ ] Success message shown after registration

## Scope

### In Scope
- Email/password registration
- Email confirmation flow
- Basic validation

### Out of Scope (Future Stories)
- Social login (OAuth)
- Two-factor authentication
- Password reset
- Profile management

## Constraints
- Must use bcrypt for password hashing
- Confirmation tokens expire in 24 hours
- Rate limit: 3 registration attempts per hour per IP

## Success Metrics
- Registration conversion rate >60%
- Email confirmation rate >80%
```

## Implementation Plan

### ./planning/user-registration/implementation-plan.md

```markdown
# Implementation Plan: User Registration

## Approach
Build a complete vertical slice for email/password registration with confirmation flow. Follow Clean Architecture with bottom-up implementation.

**Key Decision**: Use database-stored confirmation tokens (simple) over JWT tokens (stateless but complex) for MVP.

## Vertical Slice Breakdown

### Domain Layer
- [ ] User entity (id, email, passwordHash, isActive, createdAt, confirmedAt)
- [ ] Email value object (validated format)
- [ ] Password value object (complexity rules)
- [ ] ConfirmationToken value object

### Application Layer
- [ ] RegisterUserUseCase
- [ ] RegisterUserRequest/Response DTOs
- [ ] Email service interface

### Infrastructure Layer
- [ ] UserRepository with create/findByEmail
- [ ] ConfirmationTokenRepository
- [ ] EmailService implementation
- [ ] PasswordHasher (bcrypt)
- [ ] Database migration

### Framework Layer
- [ ] POST /api/auth/register endpoint
- [ ] Request validation
- [ ] Rate limiting middleware

## Task Breakdown

### P1 - Must Have
- [ ] Create User entity with email validation
- [ ] Create Password value object with complexity rules
- [ ] Implement UserRepository.create() and findByEmail()
- [ ] Implement RegisterUserUseCase
- [ ] Create POST /register endpoint
- [ ] Add basic email service (stub for now)
- [ ] Write database migration
- [ ] Unit tests for domain logic
- [ ] Integration test for registration flow

### P2 - Should Have
- [ ] Real email service integration (SendGrid/SES)
- [ ] Rate limiting implementation
- [ ] Security headers
- [ ] Comprehensive error messages
- [ ] Extended test coverage (80%+)

### P3 - Nice to Have
- [ ] Password strength indicator
- [ ] Welcome email template
- [ ] Registration analytics
- [ ] A/B testing setup

## Technical Decisions

### Password Hashing
- **Context**: Need secure password storage
- **Options**: bcrypt, Argon2, scrypt
- **Decision**: bcrypt with cost factor 12
- **Rationale**: Well-tested, good library support

### Confirmation Tokens
- **Context**: Need to verify email ownership
- **Options**: JWT (stateless), UUID (stored), Signed URL
- **Decision**: UUID stored in database
- **Rationale**: Simplest for MVP, can migrate later

### YAGNI Decisions
NOT building yet:
- Social login
- 2FA
- Email change
- Password reset

## Testing Strategy
- **Unit**: User entity, Email/Password validation, UseCase logic
- **Integration**: Repository operations, email sending
- **E2E**: Complete registration flow

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Email service downtime | Medium | High | Queue emails, retry logic |
| Password too weak | Medium | High | Enforce complexity rules |

## Implementation Order
1. Domain layer (User, Email, Password) - Foundation
2. Infrastructure (Repository, migration) - Persistence
3. Application (UseCase) - Business logic
4. Framework (API endpoint) - User interface

## Definition of Done
- [ ] All P1 tasks complete
- [ ] Tests passing (unit, integration, E2E)
- [ ] Code reviewed
- [ ] Security review completed
- [ ] Deployed to staging
```

## Session State

### ./planning/user-registration/session-state.md

```yaml
---
project: user-registration
session_count: 0
status: planned
progress:
  total_tasks: 9
  completed: 0
  percent: 0%
current_layer: not_started
branch: feat/user-registration
work_item: LIN-789
pm_tool: linear
created: 2024-01-15
---
## Status
Planning complete. Ready to begin implementation.

## Next Steps
1. Review implementation plan
2. Run `/workflow:execute ./planning/user-registration/`
3. Begin with Domain layer (User entity)

## Session History
[Empty - will populate during execution]
```

## Starting Execution

To begin implementing:

```bash
/workflow:execute ./planning/user-registration/
```

The execute command will:
1. Load session state
2. Display progress (0/9 tasks)
3. Start with first P1 task (Create User entity)
4. Track progress in TodoWrite
5. Update session state as work completes

## Key Takeaways

1. **Separate requirements from implementation** - Different audiences care about each
2. **Vertical slice breakdown** - Clear view of all layers needed
3. **P1/P2/P3 prioritization** - What's essential vs. nice-to-have
4. **YAGNI decisions explicit** - Document what we're NOT building
5. **Session state ready** - Enables multi-session continuity
