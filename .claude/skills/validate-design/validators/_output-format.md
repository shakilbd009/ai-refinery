# Validator Output Format

Shared format for all validation findings files.

## File Location

Output to: `ideas/<name>/08-validated/<validator>-findings.md`

## Template

```markdown
# <Domain> Validation Findings

**Reviewed:** <timestamp>
**Artifacts examined:** <list>
**Verdict:** PASS | PASS_WITH_NOTES | NEEDS_ATTENTION | BLOCKING

## Critical (Must Fix Before Graduation)

### [C1] <Title>
**Location:** `<file>` lines X-Y
**Issue:** <description>
**Risk:** <what could go wrong>
**Recommendation:** <specific fix>

## High (Should Fix)

### [H1] <Title>
**Location:** `<file>` lines X-Y
**Issue:** <description>
**Risk:** <what could go wrong>
**Recommendation:** <specific fix>

## Medium (Consider Fixing)

### [M1] <Title>
**Location:** `<file>` lines X-Y
**Issue:** <description>
**Risk:** <what could go wrong>
**Recommendation:** <specific fix>

## Low (Nice to Have)

### [L1] <Title>
**Location:** `<file>` lines X-Y
**Issue:** <description>
**Risk:** <what could go wrong>
**Recommendation:** <specific fix>

## Notes (Observations, Not Issues)

- <observation>
- <observation>
```

## Verdict Definitions

| Verdict | Meaning |
|---------|---------|
| PASS | No issues found |
| PASS_WITH_NOTES | Minor observations, no action needed |
| NEEDS_ATTENTION | Issues found that should be addressed |
| BLOCKING | Critical issues that must be fixed before graduation |

## Severity Definitions

| Severity | Definition | Action Required |
|----------|------------|-----------------|
| Critical | Would cause security breach, data loss, or system failure | Must fix before graduation |
| High | Significant risk or architectural problem | Should fix before graduation |
| Medium | Moderate concern, may cause issues at scale | Consider fixing |
| Low | Minor improvement opportunity | Optional |
| Notes | Observations, not issues | Informational only |
