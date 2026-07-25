# Special review modes

Load for pre-commit, deployment-range, or security-focused reviews.

### Pre-Commit Review

Before committing:
```bash
/work:review changes
```

Focuses on:
- Accidental debug code
- Sensitive data in code
- Incomplete implementations
- Missing tests for changes

### Deployment Range Review

Before deploying:
```bash
/work:review "production..HEAD"
```

Focuses on:
- Breaking changes
- Migration safety
- Rollback considerations
- Feature flags

### Security-Focused Review

For security-sensitive changes:
```bash
/work:review #123 --depth deep
```

Enhanced focus on:
- Authentication flows
- Authorization checks
- Data encryption
- Input sanitization
- OWASP compliance

