# Adding Language Support to Clean Architecture Skill

## Overview

This guide explains how to add support for a new programming language to the Clean Architecture skill.

## Directory Structure

Each language implementation should follow this structure:

```
languages/
└── {language}/
    ├── guide.md           # Language-specific patterns and idioms
    ├── examples.md        # Complete code examples
    └── validators/        # (Optional) Validation scripts
        ├── validate_imports.{ext}
        └── validate_structure.{ext}
```

## Required Files

### 1. guide.md

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

### 2. examples.md

Provide at least one complete feature example showing:

- All four layers implemented
- Proper dependency flow
- Testing at each layer
- Language idioms and best practices

### 3. validators/ (Optional but Recommended)

Create validation scripts that check:

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

- **Python**: Full implementation with validators
- **TypeScript**: Full implementation with NestJS, Next.js patterns
- **C#**: Full implementation with ASP.NET Core patterns
- **Rust**: Full implementation with Axum and Tauri patterns
- **Go**: (Community contribution welcome)
- **Java**: (Community contribution welcome)

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

## Contributing a New Language

1. Fork the repository
2. Create branch: `add-{language}-support`
3. Follow this guide to add language
4. Test thoroughly
5. Submit pull request with:
   - Language implementation
   - Example code
   - Validation scripts (if applicable)
   - Updated documentation

## Questions?

For questions about adding language support:
- Review existing implementations (Python is most complete)
- Check language-specific Clean Architecture resources
- Ask in discussions/issues

## Language-Specific Resources

### General
- "Clean Architecture" by Robert C. Martin (language-agnostic)
- "Domain-Driven Design" by Eric Evans (language-agnostic)

### Python
- "Architecture Patterns with Python" by Percival & Gregory
- "Clean Architectures in Python" by Leonardo Giordani

### JavaScript/TypeScript
- "Node.js Design Patterns" by Casciaro & Mammino
- TypeScript documentation on interfaces and types

### C#/.NET
- "Dependency Injection in .NET" by Mark Seemann
- Microsoft's Clean Architecture template

### Java
- "Clean Architecture with Spring Boot"
- Java EE patterns and best practices

### Go
- "Clean Architecture in Go" articles
- Go interfaces and struct embedding patterns

### Rust
- "Rust Design Patterns"
- Trait-based architecture patterns

## Template Files

Use these as starting points:

### Minimal Implementation

1. Copy the structure from Python
2. Adapt syntax to your language
3. Follow language conventions
4. Add language-specific patterns

### Complete Implementation

1. All files from minimal
2. Add validators
3. Add multiple examples
4. Add troubleshooting section
5. Add migration guide from other architectures