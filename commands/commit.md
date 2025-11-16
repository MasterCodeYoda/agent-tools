# /commit - Create a Conventional Commit

Create a git commit following Conventional Commits specification and project standards.

## Instructions

1. **Check current status**:
   - Run `git status` to see changes
   - Run `git diff` to review modifications

2. **Stage appropriate files**:
   - Add files related to a single logical change
   - Don't mix unrelated changes in one commit

3. **Create commit with conventional format**:

### Format
```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Formatting, missing semicolons, etc (no code change)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to build process, auxiliary tools, libraries
- **perf**: Performance improvement
- **ci**: CI/CD changes
- **build**: Build system or external dependency changes
- **revert**: Reverts a previous commit

### Scope
Optional, indicates the area of change:
- `domain`: Domain layer changes
- `application`: Application/use case layer
- `infrastructure`: Infrastructure layer
- `api`: API/controller changes
- `tests`: Test-related changes
- `deps`: Dependency updates

### Subject Rules
- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter
- No period at the end
- Maximum 50 characters

### Examples
```bash
git commit -m "feat(domain): add user entity with validation"
git commit -m "fix(api): resolve null reference in patient controller"
git commit -m "refactor(application): extract common use case pattern"
git commit -m "docs: update README with setup instructions"
git commit -m "test(domain): add unit tests for task entity"
```

### With Linear Issue
Include Linear issue ID in the subject or body:
```bash
git commit -m "fix(auth): resolve login timeout issue [LIN-123]"
```

## Quality Checks

Before committing:
1. Run `./scripts/check_all.py` to ensure code quality
2. Review changes one more time with `git diff --cached`
3. Ensure commit is atomic (one logical change)
4. Verify no secrets or sensitive data are included

## Remember
- Commits should be atomic and focused
- Each commit should leave the codebase in a working state
- Write commits as if explaining to a future developer (maybe yourself!)
- Use the body for "why" not "what" (the diff shows what)