# /fix.quality - Fix All Quality Issues

Fix all code quality issues to achieve zero warnings and errors.

## Instructions

### 1. Run Full Quality Check
```bash
./scripts/check_all.py
```

### 2. Auto-Fix What's Possible
```bash
./scripts/check_all.py --fix
```

### 3. Fix Remaining Issues Manually

#### Ruff Formatting Issues
If auto-fix didn't resolve all:
- Check line length (max 100 characters)
- Ensure consistent indentation (4 spaces)
- Remove trailing whitespace

#### Ruff Linting Issues
Common fixes:
- **Unused imports**: Remove them
- **Unused variables**: Remove or use them
- **Missing docstrings**: Add them to all public functions/classes
- **Naming conventions**: Use snake_case for functions/variables, PascalCase for classes

#### Type Checking (mypy) Issues
Common fixes:
- **Missing type hints**: Add explicit type annotations
- **Type mismatches**: Fix the types or add casts
- **Missing return types**: Add `-> Type` to functions
- **Optional without None check**: Add `if x is not None:` guard

Example fixes:
```python
# Before
def process_data(data):
    return data.strip()

# After
def process_data(data: str) -> str:
    return data.strip()
```

```python
# Before
result = maybe_none_function()
print(result.value)  # mypy error

# After
result = maybe_none_function()
if result is not None:
    print(result.value)
```

#### Security (bandit) Issues
Common fixes:
- **Hardcoded passwords**: Move to environment variables
- **SQL injection risk**: Use parameterized queries
- **Insecure random**: Use `secrets` module for security
- **Shell injection**: Avoid shell=True, use list arguments

Example fixes:
```python
# Before
password = "admin123"  # bandit warning

# After
import os
password = os.getenv("ADMIN_PASSWORD")
```

```python
# Before
query = f"SELECT * FROM users WHERE id = {user_id}"  # SQL injection risk

# After
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

#### Test Failures
- Fix failing assertions
- Update mocks if interfaces changed
- Ensure fixtures are properly scoped
- Check async test handling

### 4. Handle Pragma Comments

**Zero Tolerance Policy**: Every pragma must be justified!

```python
# WRONG
import foo  # noqa

# RIGHT (if absolutely necessary)
import foo  # noqa: F401 - Required for side effects during module initialization
```

```python
# WRONG
result = something()  # type: ignore

# RIGHT (if absolutely necessary)
result = something()  # type: ignore[arg-type]  # Third-party library has incorrect types, PR #123 submitted
```

### 5. Clean Up TODO Comments

Options:
1. Fix the TODO immediately
2. Create a Linear issue and reference it: `# TODO(LIN-123): Implement caching`
3. Remove if no longer relevant

### 6. Final Verification

Run the check again to ensure all issues are resolved:
```bash
./scripts/check_all.py
```

Expected output:
```
✅ All checks passed!
```

## Quality Standards Reminder

We have ZERO tolerance for:
- Any warnings from any tool
- Any errors from any tool
- Pragma comments without justification
- TODO comments without Linear reference
- Commented-out code
- Unused imports/variables/functions
- Type ignores without justification

## Common Gotchas

1. **Import cycles**: Restructure code or use TYPE_CHECKING guard
2. **Coverage drops**: Add tests for new code
3. **Complex types**: Extract to type aliases for readability
4. **Long lines**: Break at logical points, not just anywhere

## Remember

Quality is not negotiable. Every issue must be resolved before committing.