# ADR-004: Tiered Error Response Model

## Status
Accepted

## Context
Agents encounter various errors during execution: timeouts, malformed responses, missing data, quality issues. The question is how to handle errors - always escalate to users, or handle some autonomously?

## Decision
Use a **three-tier response model**:

| Tier | Severity | Response | User Visibility |
|------|----------|----------|-----------------|
| 1 | Minor | Retry silently | None |
| 2 | Medium | Degrade gracefully | Inline acknowledgment |
| 3 | Major | Escalate to user | Inbox item |

**Tier 1 (Minor):** Tool timeout → retry with backoff. Malformed response → retry once. Rate limit → wait and retry.

**Tier 2 (Medium):** Tool unavailable → proceed without, note gap. Doc fetch fails → use cached version. Partial data → work with available, flag uncertainty.

**Tier 3 (Major):** Cannot understand task → ask clarifying question. Conflicting requirements → present conflict. Self-critique finds issues → explain and ask guidance. Retries exhausted → surface with context.

## Consequences

### Positive
- Users not bothered by transient issues (Tier 1)
- Agents continue working when possible (Tier 2)
- Critical issues get human attention (Tier 3)
- Balance between autonomy and user control

### Negative
- Silent retries consume resources
- Degraded output may miss important information
- Must correctly classify error severity

### Mitigations
- All errors logged for debugging regardless of tier
- Tier 2 degradations acknowledged inline
- Retry limits prevent infinite loops
