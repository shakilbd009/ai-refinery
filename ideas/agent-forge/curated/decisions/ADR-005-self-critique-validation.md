# ADR-005: Self-Critique Before Validation

## Status
Accepted

## Context
Agent output needs quality control before presenting to users. Two mechanisms exist:
1. Self-critique: Agent reviews its own output
2. LLM-judge: Separate validation against constraints

Question: Should these run sequentially or is one sufficient?

## Decision
**Self-critique runs before LLM-judge validation:**

1. Agent generates initial output
2. Agent switches to "reviewer" mode and critiques output
3. If issues found → revise and re-critique (max 2 loops)
4. If clean → pass to LLM-judge for constraint validation

Self-critique checks:
- Completeness: Does output address all parts of the task?
- Consistency: Do artifacts reference each other correctly?
- Quality: Is output clear, well-structured?
- Obvious constraint awareness: Any blatant violations?

## Consequences

### Positive
- Catches quality issues early (before user sees them)
- Reduces load on formal constraint validation
- Agent improves output autonomously
- LLM-judge focuses on specific constraint compliance

### Negative
- Additional LLM calls per output (cost)
- May over-iterate on minor issues
- Self-critique quality depends on agent capability

### Mitigations
- Max 2 self-revision loops prevents over-iteration
- Self-critique focuses on general quality, not formal rules
- LLM-judge provides formal compliance gate
