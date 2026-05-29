---
title: Login Flow
priority: critical
last_updated: 2026-01-15
---

# Login Flow

## VIOLATION QCV-03: Implementation-coupled spec
## Uses CSS selectors instead of behavioral descriptions

### Scenario: Successful login

1. Navigate to `/login`
2. Type "user@example.com" into `#email-input`
3. Type "password123" into `#password-input`
4. Click `.submit-btn`
5. Assert `#dashboard-header` is visible
6. Assert URL is `/dashboard`
