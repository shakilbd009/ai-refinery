---
name: validate-devils-advocate
description: Use when challenging design assumptions, identifying blind spots, questioning decisions, or stress-testing designs. Triggers on devil's advocate, challenge assumptions, risk analysis, design critique, find holes, what could go wrong.
---

# Validate Devils Advocate

Challenges the design from a skeptical perspective, finding holes that domain-specific reviews might miss.

## Usage

```bash
/validate-devils-advocate <idea-name>
```

## Prerequisites

Curated folder must exist: `ideas/<name>/07-curated/`

If not curated, abort with: "Run /curating-artifacts first"

## Focus Areas

- **Assumptions** - Unstated assumptions, untested hypotheses, optimistic estimates
- **Risks** - What could go wrong, failure modes, dependencies on external factors
- **Decisions** - Why this approach over alternatives, decision reversibility
- **Stress Testing** - Edge cases, adversarial users, hostile environments
- **Blind Spots** - What's missing, unconsidered scenarios, integration gaps
- **Complexity** - Overengineering, unnecessary features, simpler alternatives

## Artifacts to Examine

All curated artifacts:
- `07-curated/requirements.md`
- `07-curated/architecture/`
- `07-curated/decisions/`
- `07-curated/trade-offs.md`
- `07-curated/edge-cases/`
- `07-curated/security/`
- `07-curated/performance.md`
- Any other files in `07-curated/`

<details>
<summary>Execution</summary>

Use the `devils-advocate` agent via Task tool:

```
Task (devils-advocate):
  Prompt: Challenge the design in ideas/<name>/07-curated/ as a devil's advocate.

  Your role: Be constructively skeptical. Find the holes, question the decisions,
  identify what could go wrong. Don't just validate - stress test.

  Focus on the areas listed above (Assumptions, Risks, Decisions, etc.)

  Examine ALL files in:
  - 07-curated/

  Output findings to: ideas/<name>/08-validated/devils-advocate-findings.md

  Use format from: [_output-format.md](_output-format.md)
```

</details>

## Output

Creates: `ideas/<name>/08-validated/devils-advocate-findings.md`

## Severity Guide

| Severity | Examples |
|----------|----------|
| Critical | Core assumption likely wrong, fundamental design flaw, blocking dependency unaddressed |
| High | Significant risk not mitigated, questionable decision without rationale, major gap |
| Medium | Minor assumption worth validating, alternative worth considering, complexity concern |
| Low | Nitpick, minor simplification opportunity, documentation suggestion |

## Perspective

Unlike domain-specific validators, devil's advocate doesn't validate technical correctness. It asks:

- "What if this assumption is wrong?"
- "What happens when X fails?"
- "Why not do Y instead?"
- "What are we not seeing?"
- "Is this actually necessary?"
