# Completeness Report Format

Output format for completeness score results.

## Success Report (100%)

When all criteria pass:

```
Completeness check passed: {passed}/{total} criteria met

Components ({component_passed}/{component_total}):
  ✓ {component-name}: all criteria met
  ✓ {component-name}: all criteria met
  ...

ADRs ({adr_passed}/{adr_total}):
  ✓ All {adr_count} ADRs have required sections

Edge Cases ({edge_passed}/4):
  ✓ All categories covered

Required Documents ({doc_passed}/3):
  ✓ security/threat-model.md
  ✓ operations/runbooks.md
  ✓ performance.md

Ready for graduation.
```

## Failure Report (<100%)

When any criteria fail:

```
Graduation blocked: {failed_count} criteria not met

Components:
  ✗ {component-name}: {failure_message}
  ✗ {component-name}: {failure_message}
  ✓ {component-name}: all criteria met

ADRs:
  ✗ ADR-{number}: {failure_message}
  ✓ ADR-{number}: all criteria met

Edge Cases:
  ✗ {category}: {failure_message}

Required Documents:
  ✗ {path}: {failure_message}

Score: {percentage}% ({passed}/{total} criteria)
Required: 100%

Fix these issues in 07-curated/ and retry.
```

## Symbols

| Symbol | Meaning |
|--------|---------|
| ✓ | Criterion passed |
| ✗ | Criterion failed |

## Grouping Rules

1. **Components** - Group by component file, list each failure
2. **ADRs** - Group by ADR number, list each failure
3. **Edge Cases** - List missing categories
4. **Required Documents** - List missing or incomplete files

## Failure Messages

Use messages from CRITERIA.md:

| Category | Possible Failures |
|----------|-------------------|
| Components | "missing overview section", "missing data flow diagram", "missing edge cases section", "missing failure modes section" |
| ADRs | "missing context/problem section", "missing decision section", "missing consequences section", "missing alternatives considered" |
| Edge Cases | "missing timing edge cases", "missing data boundary cases", "missing integration edge cases", "missing state transition cases" |
| Required Docs | "missing security threat model", "missing operations runbooks", "missing performance targets with metrics" |

## Example Failure Report

```
Graduation blocked: 3 criteria not met

Components:
  ✗ inventory-reservation: missing failure modes section
  ✗ discount-code: missing data flow diagram
  ✓ checkout-flow: all criteria met
  ✓ review-moderation: all criteria met

ADRs:
  ✗ ADR-003: missing alternatives considered
  ✓ 11 other ADRs passed

Edge Cases:
  ✓ All categories covered

Required Documents:
  ✓ security/threat-model.md
  ✓ operations/runbooks.md
  ✓ performance.md

Score: 85% (17/20 criteria)
Required: 100%

Fix these issues in 07-curated/ and retry.
```

## When Called from /graduate

Include context about the blocked operation:

```
/graduate manik-golden-honey-co ~/projects/golden-honey

Checking completeness...

Graduation blocked: 3 criteria not met
[... detailed report ...]

Fix these issues and run /graduate again.
```

## When Called Standalone

Just show the report without graduation context:

```
/completeness-score manik-golden-honey-co

[... report ...]
```
