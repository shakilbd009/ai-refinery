---
name: validate-architecture
description: Use when reviewing designs for architectural quality, pattern consistency, component boundaries, coupling issues, or scalability concerns. Triggers on architecture review, design review, structure audit.
---

# Validate Architecture

Reviews curated design artifacts for architectural quality and concerns.

## Usage

```bash
/validate-architecture <idea-name>
```

## Prerequisites

Curated folder must exist: `ideas/<name>/07-curated/`

If not curated, abort with: "Run /curating-artifacts first"

## Focus Areas

- **Pattern Consistency** - Consistent use of patterns across components
- **Component Boundaries** - Clear responsibilities, proper encapsulation
- **Coupling Analysis** - Loose coupling, high cohesion, dependency direction
- **Scalability Design** - Horizontal scaling, statelessness, bottleneck identification
- **Maintainability** - Testability, debuggability, onboarding complexity
- **Separation of Concerns** - Layers, domains, cross-cutting concerns

## Artifacts to Examine

Primary:
- `07-curated/architecture/` - All architecture docs
- `07-curated/decisions/` - ADRs and trade-off records
- `07-curated/trade-offs.md` - Trade-off summary

Secondary:
- `07-curated/requirements.md` - Alignment check
- Component docs with architectural implications

## Execution

Use the `architecture-strategist` agent via Task tool:

```
Task (architecture-strategist):
  Prompt: Review ideas/<name>/07-curated/ for architecture quality.

  Focus on:
  - Pattern consistency across components
  - Component boundaries and responsibilities
  - Coupling between components
  - Scalability concerns
  - Maintainability and testability
  - Separation of concerns

  Examine these files:
  - 07-curated/architecture/*
  - 07-curated/decisions/*
  - 07-curated/trade-offs.md
  - 07-curated/requirements.md

  Output findings to: ideas/<name>/08-validated/architecture-findings.md

  Use format from: [_output-format.md](_output-format.md)
```

## Output

Creates: `ideas/<name>/08-validated/architecture-findings.md`

## Severity Guide

| Severity | Examples |
|----------|----------|
| Critical | Circular dependencies, missing critical component, architectural deadlock |
| High | Tight coupling between domains, scalability bottleneck, unclear ownership |
| Medium | Inconsistent patterns, minor boundary violation, complexity hotspot |
| Low | Naming inconsistency, documentation gap, minor refactoring opportunity |
