---
name: code-patterns
description: Language-specific coding patterns for Python, TypeScript/React, and C#/.NET. Covers type safety, testing strategies, error handling, async patterns, and framework best practices. Routes to the appropriate language guide based on project context.
---

# Code Patterns

This skill provides language-specific coding standards, patterns, and best practices. It routes to detailed guides based on the programming language in use.

## When to Use This Skill

- Writing new code in Python, TypeScript, or C#
- Reviewing code for best practices
- Setting up testing patterns
- Implementing error handling strategies
- Configuring project structure and tooling

## Language Selection

### Working with Python?

**See: `languages/python.md`**

Covers:
- Python 3.13+ with type hints and mypy strict mode
- Pydantic models and validation
- pytest fixtures, parametrization, and test organization
- FastAPI patterns (dependency injection, request/response models)
- Async/await patterns and context managers
- Clean Architecture implementation in Python

### Working with TypeScript/React?

**See: `languages/typescript.md`**

Covers:
- TypeScript 5.3+ with strict mode
- React 18+ functional components and hooks
- Runtime portability (Bun/Node.js) with adapters
- Server Components and hybrid SSR patterns
- Zustand state management
- React Hook Form with Zod validation
- Multi-step wizard patterns
- Data visualization components
- Vitest + React Testing Library

### Working with C#/.NET?

**See: `languages/csharp.md`**

Covers:
- .NET 8+ with C# 12 and nullable reference types
- Entity Framework Core patterns and configurations
- Result pattern and RFC 7807 error handling
- MediatR for CQRS patterns
- xUnit testing with Moq and FluentAssertions
- Clean Architecture project structure
- ASP.NET Core controller patterns

### Working with Rust?

**See: `languages/rust.md`**

Covers:
- Rust 1.75+ with Clippy pedantic lints
- Trait-based dependency injection
- async/await with Tokio
- **Structured concurrency** (JoinSet, TaskTracker, CancellationToken)
- Tauri v2 desktop app patterns
- **tauri-specta** for type-safe frontend bindings
- SQLx and Diesel database access
- mockall, proptest, and **insta snapshot testing**
- thiserror/anyhow/**snafu** for error handling

## Universal Principles

These principles apply across all languages:

### Naming Conventions
- Use clear, intention-revealing names
- Follow language conventions (PascalCase in C#, snake_case in Python, camelCase in TypeScript)
- Avoid abbreviations except for well-known ones (e.g., `id`, `url`)

### Error Handling Philosophy
- Prefer explicit error handling over exceptions for expected failures
- Use Result/Either patterns for operations that can fail
- Reserve exceptions for truly exceptional circumstances
- Always handle errors at appropriate boundaries

### Testing Pyramid
- **Domain/Unit Tests**: Fast, pure logic tests with no external dependencies
- **Application Tests**: Mock external dependencies, test use case orchestration
- **Infrastructure Tests**: Test with real dependencies (test containers)
- **Integration/E2E Tests**: Full stack tests for critical paths

### Code Organization
- Organize by feature/domain, not by technical layer
- Keep related code together (colocation)
- Explicit dependencies through constructor/function injection
- Clear layer boundaries following Clean Architecture

### Type Safety
- Always use the strongest type system features available
- Avoid `any`/`dynamic`/untyped patterns
- Define domain types rather than using primitives
- Leverage compile-time checks over runtime validation

## Extended Resources

For detailed language-specific patterns (loaded on request only):

- **Python**: `languages/python.md` - Comprehensive Python patterns and standards
- **TypeScript**: `languages/typescript.md` - TypeScript/React patterns and best practices
- **C#**: `languages/csharp.md` - C#/.NET enterprise patterns

## Related Skills

- **clean-architecture**: For architectural patterns and layer organization
- **spec**: For feature planning and implementation workflow
