# ADR-014: LLM-Judge Constraint Validation

## Status
Accepted

## Context
SME-defined constraints need enforcement. Options:
1. Static analysis - code/AST parsing (limited to code rules)
2. Rule engine - formal rule definitions (complex to author)
3. LLM-as-judge - natural language rules evaluated by LLM

## Decision
Use **hybrid deterministic + LLM validation** for constraint enforcement:

Pure LLM-as-judge is probabilistic and unsuitable for critical constraints. We use a **tiered validation approach**:

### Validation Tiers

| Tier | Method | Use Case | Reliability |
|------|--------|----------|-------------|
| **Tier 1: Deterministic** | Code/regex | Hard rules, security, formats | 100% |
| **Tier 2: Structured** | JSON schema, AST | Data structure validation | 100% |
| **Tier 3: LLM-Judge** | Natural language | Quality, style, semantics | ~90% |

### Validation Flow

```
Agent generates output
        ↓
┌──────────────────────────────────────┐
│ Tier 1: Deterministic Checks         │
│ - Blocklist patterns (security)      │
│ - Required field presence            │
│ - Format validation (URLs, dates)    │
│ - Size/length limits                 │
│ → Hard fail if violated              │
└──────────────────────────────────────┘
        ↓ Pass
┌──────────────────────────────────────┐
│ Tier 2: Structured Validation        │
│ - JSON schema compliance             │
│ - API contract adherence             │
│ - Required artifact structure        │
│ → Hard fail if violated              │
└──────────────────────────────────────┘
        ↓ Pass
┌──────────────────────────────────────┐
│ Tier 3: LLM-Judge (semantic)         │
│ - Quality assessment                 │
│ - Style guide compliance             │
│ - SME constraint evaluation          │
│ → Soft fail: retry or escalate       │
└──────────────────────────────────────┘
        ↓
Pass → Ready for user review
```

### Deterministic Validators

```go
type DeterministicValidator struct {
    blocklist    []regexp.Regexp  // Security patterns
    allowlist    []regexp.Regexp  // Required patterns
    formatChecks map[string]FormatChecker
}

func (v *DeterministicValidator) Validate(output AgentOutput) ValidationResult {
    // Check blocklist (security-critical)
    for _, pattern := range v.blocklist {
        if pattern.MatchString(output.Content) {
            return ValidationResult{
                Pass:    false,
                Tier:    "deterministic",
                Reason:  "Blocked pattern detected",
                CanRetry: false,  // Security violations don't retry
            }
        }
    }

    // Check required patterns (allowlist)
    for _, pattern := range v.allowlist {
        if !pattern.MatchString(output.Content) {
            return ValidationResult{
                Pass:    false,
                Tier:    "deterministic",
                Reason:  "Required pattern missing",
                CanRetry: true,
            }
        }
    }

    return ValidationResult{Pass: true}
}
```

### LLM-Judge (for semantic validation only)

Reserved for constraints that cannot be expressed deterministically:

```go
type LLMJudge struct {
    provider LLMProvider
}

func (j *LLMJudge) Evaluate(output AgentOutput, constraints []SemanticConstraint) ValidationResult {
    // Only evaluate semantic constraints
    // Security and structural checks are handled by Tier 1/2

    prompt := buildJudgingPrompt(output, constraints)
    response, err := j.provider.Complete(prompt)

    if err != nil {
        // LLM failure shouldn't block - escalate to human
        return ValidationResult{
            Pass:     false,
            Reason:   "Validation service unavailable",
            CanRetry: false,
            Escalate: true,
        }
    }

    return parseJudgingResponse(response)
}
```

### Constraint Categories by Tier

| Category | Tier | Example |
|----------|------|---------|
| Security blocklist | Deterministic | No hardcoded secrets |
| Format requirements | Deterministic | Valid JSON, URL format |
| API schema | Structured | Response matches OpenAPI spec |
| Data model | Structured | Entity relationships valid |
| Writing quality | LLM-Judge | Clear, concise prose |
| Style guide | LLM-Judge | Follows company voice |
| Domain accuracy | LLM-Judge | Technically correct claims |

Constraint categories: allowlist (deterministic), blocklist (deterministic), structural (schema), quality (LLM), security (deterministic).

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
