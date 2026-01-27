# ADR-006: Fixed Linear Pipeline

## Status
Accepted

## Context
Projects could follow flexible workflows (any order) or fixed sequences. Options:
1. Flexible: Users choose which phases to do and in what order
2. Fixed: Predetermined sequence that all projects follow
3. Templates: Predefined sequences users can customize

## Decision
Use a **fixed linear pipeline** for all projects:

```
Requirements → Architecture → Code → Security Review
```

No skipping, no reordering. Every project follows the same sequence.

## Consequences

### Positive
- Simple and predictable - users always know what comes next
- Agents always know what came before
- Consistent mental model across all projects
- Ensures all code is security-reviewed
- Reduces decision fatigue

### Negative
- No flexibility for projects that don't fit the mold
- Cannot skip phases even when unnecessary
- May feel constraining for experienced users

### Mitigations
- Phases can be brief if little work needed
- Agent conversation can be minimal for simple phases
- Security review confirms "no issues" quickly if code is clean
- Fixed structure prevents cutting corners on important steps
