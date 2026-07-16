# Setup complete summary

```markdown
## Sentinel Setup Complete

**Config**: sentinel.config.yaml
**NL Specs directory**: specs/
**Generated Tests directory**: tests/
**Seed fixture**: tests/seed.spec.ts
**Base URL**: {base_url}
**Auth**: {strategy}
**Authoring adapters**: {providers}

### Directory Structure

specs/          <- NL spec files (author here)
tests/          <- generated .spec.ts files
  seed.spec.ts  <- fixture setup
playwright.config.ts
sentinel.config.yaml
README.md       <- quick-reference guide
.gitignore

### What's Next?

1. **Discover features** — Run `/qa:discover` to create NL specs
2. **Generate tests** — Use Playwright Planner/Generator to convert NL specs to .spec.ts
3. **Run tests** — `npx playwright test` to execute generated tests
4. **Audit drift** — Run `/workflow:audit` (qa domain) to check spec-test-app alignment (planned dedicated `/qa:audit`)
```
