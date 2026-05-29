---
title: User Notification Preferences
project: acme-app
created: 2026-03-21
---

# User Notification Preferences

## Problem

Users currently receive all notifications with no ability to control
which types they receive or how they're delivered. Users have requested
the ability to manage their notification preferences.

## Requirements

### Must Have

1. Users can view their current notification preferences on a settings page
2. Users can toggle email notifications on/off per category:
   - Order updates (placed, shipped, delivered)
   - Marketing emails (promotions, newsletters)
   - Account security (login alerts, password changes)
3. Users can toggle push notifications on/off per category (same categories)
4. Preference changes take effect immediately (no "save" delay)
5. New users default to all notifications enabled

### Should Have

6. Users see a preview of what each notification category looks like
7. Unsubscribe links in emails honor the preference settings

### Out of Scope

- SMS notification channel (future phase)
- Notification scheduling (quiet hours)
- Per-item notification granularity (e.g., notify only for orders > $100)

## Technical Context

- Backend: Python/FastAPI
- Database: PostgreSQL
- Frontend: React/TypeScript
- Existing auth system with JWT tokens
- No existing notification preference tables
