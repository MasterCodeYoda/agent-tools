# Example: Planning a User Registration Feature

This example demonstrates how to plan a complete vertical slice for user registration functionality.

## Work Item Details

**Tool**: Linear
**ID**: LIN-789
**Title**: Implement user registration
**Priority**: P0 (Critical)
**Estimate**: 8 story points

## User Story

As a new visitor, I want to register for an account so that I can access personalized features.

## Acceptance Criteria

- [ ] User can enter email and password
- [ ] Email validation is performed
- [ ] Password meets security requirements
- [ ] Duplicate emails are rejected
- [ ] User receives confirmation email
- [ ] Account is created but inactive until confirmed
- [ ] Success message shown after registration

## Vertical Slice Breakdown

### 1. Domain Layer

```markdown
**Entities**:
- User entity
  - id: UUID
  - email: string (unique)
  - passwordHash: string
  - isActive: boolean
  - createdAt: datetime
  - confirmedAt: datetime?

**Value Objects**:
- Email (validated format)
- Password (min 8 chars, complexity rules)
- ConfirmationToken

**Business Rules**:
- Email must be unique
- Password must meet complexity requirements
- New users start as inactive
- Confirmation required within 24 hours
```

### 2. Application Layer

```markdown
**Use Case**: RegisterUserUseCase

**Request**:
- email: string
- password: string
- termsAccepted: boolean

**Response**:
- success: boolean
- userId?: string
- message: string
- errors?: ValidationError[]

**Flow**:
1. Validate input
2. Check email uniqueness
3. Hash password
4. Create user (inactive)
5. Generate confirmation token
6. Send confirmation email
7. Return success response
```

### 3. Infrastructure Layer

```markdown
**Repository Methods**:
- UserRepository.create(user: User): User
- UserRepository.findByEmail(email: string): User?
- UserRepository.existsByEmail(email: string): boolean

**External Services**:
- EmailService.sendConfirmation(email: string, token: string): void
- PasswordHasher.hash(password: string): string

**Database**:
- users table schema
- Unique index on email
- Migration script
```

### 4. Framework Layer

```markdown
**API Endpoint**:
- POST /api/auth/register
- Request body validation
- Rate limiting (3 attempts per hour)
- CORS configuration

**Request Model**:
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "termsAccepted": true
}

**Response Model**:
Success: 201 Created
{
  "message": "Registration successful. Please check your email.",
  "userId": "uuid-here"
}

Error: 400 Bad Request
{
  "errors": [{
    "field": "email",
    "message": "Email already registered"
  }]
}
```

### 5. Testing Strategy

```markdown
**Unit Tests**:
- User entity validation
- Email value object validation
- Password complexity rules
- RegisterUserUseCase logic

**Integration Tests**:
- UserRepository database operations
- EmailService integration
- Unique email constraint

**E2E Tests**:
- Complete registration flow
- Duplicate email rejection
- Invalid input handling
- Rate limiting
```

## Task Breakdown

### P1 - Must Have (Core Functionality)
- [ ] User entity with email/password (1h)
- [ ] Email and Password value objects (30m)
- [ ] UserRepository with create/findByEmail (1h)
- [ ] RegisterUserUseCase implementation (1.5h)
- [ ] POST /register endpoint (1h)
- [ ] Basic email service stub (30m)
- [ ] Database migration (30m)
- [ ] Happy path tests (1h)

**P1 Total: ~6.5 hours**

### P2 - Should Have (Production Ready)
- [ ] Comprehensive validation (30m)
- [ ] Real email service integration (1h)
- [ ] Rate limiting implementation (30m)
- [ ] Security headers (15m)
- [ ] Error handling edge cases (30m)
- [ ] Additional test coverage (45m)

**P2 Total: ~3.5 hours**

### P3 - Nice to Have (Enhancements)
- [ ] Password strength indicator (30m)
- [ ] Social login options (2h)
- [ ] Welcome email template (30m)
- [ ] Analytics tracking (30m)
- [ ] A/B testing setup (1h)

**P3 Total: ~4.5 hours**

## Technical Decisions

### Decision: Confirmation Token Strategy

**Options Considered**:
1. JWT tokens - Stateless, but complex
2. Random UUID - Simple, requires storage
3. Signed URLs - Middle ground

**Decision**: Use random UUID stored in database
**Rationale**: Simplest for MVP, can migrate later

### Decision: Password Hashing

**Options Considered**:
1. bcrypt - Industry standard
2. Argon2 - Newer, more secure
3. scrypt - Good but less common

**Decision**: bcrypt with cost factor 12
**Rationale**: Well-tested, good library support

### YAGNI Decisions

**Not Building Yet**:
- Social login (add when requested)
- Two-factor authentication (phase 2)
- Email change functionality (separate story)
- Profile management (separate story)
- Password reset (separate story)

## Risk Assessment

**Technical Risks**:
- Email service downtime (Medium)
  - Mitigation: Queue emails, retry logic
- Database unique constraint race condition (Low)
  - Mitigation: Proper error handling

**Security Risks**:
- Weak passwords (Medium)
  - Mitigation: Enforce complexity rules
- Email enumeration (Medium)
  - Mitigation: Same response for all failures

**Business Risks**:
- High bounce rate if process too complex (Medium)
  - Mitigation: Simple form, clear instructions

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Unit test coverage >80%
- [ ] Integration tests passing
- [ ] E2E test verifies full flow
- [ ] Security review completed
- [ ] API documentation updated
- [ ] No critical vulnerabilities
- [ ] Performance <200ms response time
- [ ] Deployed to staging environment
- [ ] Product owner approval

## Project Management Updates

### Linear Updates
```markdown
Status: Backlog → In Progress
Comment: "Vertical slice planned. Starting implementation."
Estimate: 8 points (~1.5 days)
Labels: vertical-slice, authentication
```

### Commit Message Template
```bash
feat(auth): implement user registration vertical slice [LIN-789]

- Add User domain entity with validation
- Implement RegisterUserUseCase
- Add UserRepository with unique email check
- Create POST /register endpoint
- Include email confirmation flow
- Add comprehensive test coverage

Closes: LIN-789
```

## Success Metrics

- Registration conversion rate >60%
- Email confirmation rate >80%
- Time to complete <2 minutes
- Error rate <1%
- Support tickets <5 per 100 registrations

## Notes

- Coordinate with UX team on error messages
- Review email template with marketing
- Ensure GDPR compliance for EU users
- Consider rate limiting per IP vs per email
- Monitor for automated bot registrations