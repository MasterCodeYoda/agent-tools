# Adding Language Support to Clean Architecture Skill

## Overview

This guide explains how to add support for a new programming language to the Clean Architecture skill.

## Directory Structure

Each language implementation lives in its own directory under `languages/`:

```
languages/
└── {language}/
    ├── guide.md           # Required — language-specific patterns and idioms
    ├── examples.md        # Optional — complete code examples
    └── validators/        # Optional — validation scripts
        ├── validate_imports.{ext}
        └── validate_structure.{ext}
```

## Required Files

### 1. guide.md (Required)

The main guide should cover:

- **Type System Integration**: How to use the language's type system for Clean Architecture
- **Domain Layer Patterns**: Entities, value objects, services in this language
- **Application Layer Patterns**: Use cases, DTOs, ports
- **Infrastructure Layer Patterns**: Repository implementations, gateways
- **Frameworks Layer Patterns**: Controllers, dependency injection
- **Testing Patterns**: Unit, integration, and e2e testing approaches
- **Project Structure**: Recommended directory layout
- **Tool Integration**: Linters, formatters, type checkers
- **Common Pitfalls**: Language-specific issues to avoid

### 2. examples.md (Optional)

A complete feature example showing:

- All four layers implemented
- Proper dependency flow
- Testing at each layer
- Language idioms and best practices

### 3. validators/ (Optional)

Validation scripts that check:

- **Import validation**: Dependencies flow inward
- **Structure validation**: Files in appropriate layers
- **Naming conventions**: Language-specific conventions
- **Encapsulation patterns**: Private/public members

## Step-by-Step Guide

### Step 1: Create Directory Structure

```bash
mkdir -p languages/{language}/validators
```

### Step 2: Write the Guide

Start with this template for `guide.md`:

```markdown
# {Language} Clean Architecture Guide

## Overview
[Brief introduction about implementing Clean Architecture in this language]

## {Language} Type System for Clean Architecture
[How to define interfaces/contracts]

## Domain Layer Patterns
### Entities
[Code example]

### Value Objects
[Code example]

### Domain Services
[Code example]

## Application Layer Patterns
### Use Cases
[Code example]

### Request/Response Models
[Code example]

## Infrastructure Layer Patterns
### Repository Implementation
[Code example]

### Gateway Implementation
[Code example]

## Frameworks Layer Patterns
### Controllers/Handlers
[Code example]

### Dependency Injection
[Code example]

## Testing Patterns
[Testing approaches and examples]

## Project Structure
[Recommended directory layout]

## {Language}-Specific Tools
[Linters, formatters, build tools]

## Common {Language} Pitfalls
[Language-specific issues to avoid]
```

### Step 3: Create Examples

In `examples.md`, implement a complete feature (e.g., User Registration, Task Creation) showing:

```markdown
# {Language} Clean Architecture Examples

## Complete Feature Example: [Feature Name]

### Domain Layer
[Entity and value object code]

### Application Layer
[Use case implementation]

### Infrastructure Layer
[Repository and gateway implementations]

### Frameworks Layer
[API endpoint or CLI command]

### Tests
[Test examples for each layer]
```

### Step 4: Create Validators (Optional)

If the language supports it, create validation scripts:

1. **validate_imports**: Check dependency direction
2. **validate_structure**: Check naming and file organization

### Step 5: Update Main Skill

After adding a language, update these files:

1. **SKILL.md**: Add language to the supported list
2. **This README**: Add language to supported languages list

## Supported Languages

Currently supported languages:

| Language | guide.md | examples.md | validators/ |
|----------|----------|-------------|-------------|
| **Python** | Yes | Yes | Yes |
| **TypeScript** | Yes | — | — |
| **C#** | Yes | — | — |
| **Rust** | Yes | — | — |

## Guidelines for Language Implementations

### DO:
- ✅ Follow language idioms and conventions
- ✅ Use the language's type system effectively
- ✅ Provide runnable code examples
- ✅ Include testing patterns
- ✅ Show real-world patterns, not just theory
- ✅ Include tool configuration (linters, formatters)

### DON'T:
- ❌ Force patterns that don't fit the language
- ❌ Ignore language-specific features
- ❌ Provide only abstract examples
- ❌ Skip error handling patterns
- ❌ Forget about language-specific pitfalls

## Testing Your Implementation

Before submitting:

1. **Validate Examples**: Ensure all code examples compile/run
2. **Check Completeness**: All four layers covered
3. **Test Validators**: Run validation scripts on example code
4. **Review Clarity**: Guide is clear for language newcomers
5. **Verify Links**: All internal references work

## Example Validation Script Structure

For compiled languages (TypeScript, C#, Java):

```
validators/
├── validate_imports.{ext}    # Parse AST, check imports
├── validate_structure.{ext}  # Check file organization
└── run_all.sh                # Run all validators
```

For interpreted languages (Python, Ruby, JavaScript):

```
validators/
├── validate_imports.{ext}    # Use language parser
├── validate_structure.{ext}  # Pattern matching
└── run_all.sh                # Run all validators
```

## Adding a New Language

1. Create `languages/{language}/guide.md` following the template in Step 2 above
2. Update `SKILL.md` to add the language to the supported list
3. Optionally add `examples.md` and `validators/` (see Python for reference)

The Python implementation is the most complete reference — start there when adding a new language.