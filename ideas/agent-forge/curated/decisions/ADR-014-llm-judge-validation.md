# ADR-014: LLM-Judge Constraint Validation

## Status
Accepted

## Context
SME-defined constraints need enforcement. Options:
1. Static analysis - code/AST parsing (limited to code rules)
2. Rule engine - formal rule definitions (complex to author)
3. LLM-as-judge - natural language rules evaluated by LLM

## Decision
Use **LLM-as-judge** for constraint validation:

- Constraints defined in natural language
- LLM evaluates output against constraints
- Returns pass/fail with explanation
- Failed items get feedback for retry

Validation flow:
```
Agent generates output
        ↓
LLM-judge evaluates against constraints
        ↓
Pass → Ready for user review
Fail → Feedback to agent → Retry (max 3)
        ↓
Retries exhausted → Escalation
```

Constraint categories: allowlist, blocklist, quality, security.

## Consequences

### Positive
- Natural language rules are SME-friendly
- Flexible - can express complex requirements
- No formal rule language to learn
- Can evaluate semantic meaning, not just syntax

### Negative
- LLM evaluation is probabilistic, not deterministic
- Additional LLM calls (cost)
- May have false positives/negatives
- Harder to debug than formal rules

### Mitigations
- Constraints include examples of violations
- Multiple retry attempts before escalation
- Escalation path for edge cases
- Constraint examples help LLM understand intent
