---
name: validate-performance
description: Use when reviewing designs for performance bottlenecks, N+1 queries, caching opportunities, scaling limits, or resource constraints. Triggers on performance review, optimization audit, scalability check.
---

# Validate Performance

Reviews curated design artifacts for performance concerns and optimization opportunities.

## Usage

```bash
/validate-performance <idea-name>
```

## Prerequisites

Curated folder must exist: `ideas/<name>/07-curated/`

If not curated, abort with: "Run /curating-artifacts first"

## Focus Areas

- **Bottlenecks** - Synchronous operations on hot paths, blocking calls
- **Database** - N+1 queries, missing indexes, query complexity, connection pooling
- **Caching** - Cache opportunities, invalidation strategy, cache warming
- **Scaling Limits** - Single points of contention, state that prevents horizontal scaling
- **Resource Constraints** - Memory usage, CPU-bound operations, I/O patterns
- **Hot Paths** - Critical user flows, high-frequency operations

## Artifacts to Examine

Primary:
- `07-curated/performance.md` - Performance considerations
- `07-curated/architecture/data-model.md` - Data access patterns
- `07-curated/architecture/api-contracts.md` - API performance characteristics

Secondary:
- Component docs with performance implications
- `07-curated/edge-cases/high-volume.md` or similar

## Execution

Use the `performance-oracle` agent via Task tool:

```
Task (performance-oracle):
  Prompt: Review ideas/<name>/07-curated/ for performance concerns.

  Focus on:
  - Bottlenecks on hot paths
  - N+1 query patterns
  - Missing caching opportunities
  - Scaling limits
  - Resource constraints
  - High-frequency operation optimization

  Examine these files:
  - 07-curated/performance.md
  - 07-curated/architecture/data-model.md
  - 07-curated/architecture/api-contracts.md
  - 07-curated/architecture/components/*
  - 07-curated/edge-cases/*

  Output findings to: ideas/<name>/08-validated/performance-findings.md

  Use format from: [_output-format.md](_output-format.md)
```

## Output

Creates: `ideas/<name>/08-validated/performance-findings.md`

## Severity Guide

| Severity | Examples |
|----------|----------|
| Critical | Unbounded query, O(n²) on large dataset, blocking call in request path |
| High | N+1 query pattern, missing index on frequent query, no pagination |
| Medium | Cacheable data not cached, suboptimal batch size, sync where async possible |
| Low | Minor optimization opportunity, nice-to-have caching, logging verbosity |
