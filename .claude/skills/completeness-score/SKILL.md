---
name: completeness-score
description: Validate curated artifacts meet quality criteria before graduation
---

# Completeness Score Skill

Validates that curated artifacts meet all required quality criteria. Hard gate for `/graduate`.

## Usage

```bash
# Standalone validation
/completeness-score <idea-name>

# Automatically invoked by /graduate
```

## Prerequisites

- Idea must have `07-curated/` folder (run `/curating-artifacts` first)
- All curation agents must have completed

## Process

### 1. Load Curated Artifacts

```bash
# Find all files to validate
ls ideas/<idea-name>/07-curated/
ls ideas/<idea-name>/07-curated/architecture/components/
ls ideas/<idea-name>/07-curated/decisions/
ls ideas/<idea-name>/07-curated/edge-cases/
ls ideas/<idea-name>/07-curated/security/
ls ideas/<idea-name>/07-curated/operations/
```

### 2. Validate Each Category

Validate in parallel:
1. **Components** - Check each `architecture/components/*.md`
2. **ADRs** - Check each `decisions/ADR-*.md`
3. **Edge Cases** - Check `edge-cases/` structure
4. **Required Documents** - Check existence and content

See [CRITERIA.md](./CRITERIA.md) for detailed validation rules.

### 3. Compile Results

For each file/category:
- Track pass/fail per criterion
- Collect specific failure messages
- Calculate total score

### 4. Generate Report

See [REPORT-FORMAT.md](./REPORT-FORMAT.md) for output format.

**On Pass (100%):**
```
Completeness check passed: 20/20 criteria met

Components (4/4):
  ✓ checkout-flow: all criteria met
  ✓ inventory-reservation: all criteria met
  ✓ discount-code: all criteria met
  ✓ review-moderation: all criteria met

ADRs (12/12):
  ✓ All 12 ADRs have required sections

Edge Cases (4/4):
  ✓ All categories covered

Required Documents (3/3):
  ✓ security/threat-model.md
  ✓ operations/runbooks.md
  ✓ performance.md

Ready for graduation.
```

**On Fail (<100%):**
- Abort with detailed failure report
- Show exactly what's missing
- Provide actionable fix instructions

## Integration with /graduate

When invoked by `/graduate`:
1. Run completeness check first
2. If fails → abort graduation immediately
3. If passes → continue to repo creation

```
/graduate <idea-name> <target-path>
    │
    ├─► /completeness-score <idea-name>
    │       │
    │       ├─► FAIL: Abort, show report
    │       │
    │       └─► PASS: Continue...
    │
    └─► Create repo, transfer docs, etc.
```

## Error Handling

| Error | Resolution |
|-------|------------|
| No 07-curated/ folder | Run `/curating-artifacts <idea-name>` first |
| Missing component file | Check curation completed successfully |
| Invalid markdown | Fix file format, re-run check |
