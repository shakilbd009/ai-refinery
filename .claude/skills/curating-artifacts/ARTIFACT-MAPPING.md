# Artifact Mapping

Source files from stages 1-6 map to curated output as follows:

| Source (stages 1-6) | Target (curated/) |
|---------------------|-------------------|
| stage-1/idea.md | overview.md (partial) |
| stage-2/requirements.md | requirements.md |
| stage-3/*trade-off*.md | trade-offs.md |
| stage-3/*recommendation*.md | trade-offs.md |
| stage-4/architecture*.md | architecture/overview.md |
| stage-4/database-schema.md | architecture/data-model.md |
| stage-4/api-contracts.md | architecture/api-contracts.md |
| stage-4/*-L1.md | architecture/components/*.md (merged) |
| stage-5/*-L2.md | architecture/components/*.md (merged) |
| stage-6/*-L3.md | architecture/components/*.md (merged) |
| stage-6/edge-cases*.md | edge-cases/*.md (split by category) |
| stage-6/security-threat-model.md | security/threat-model.md |
| stage-6/compliance-*.md | security/compliance/*.md |
| stage-6/operational-runbooks.md | operations/runbooks.md |
| stage-6/monitoring*.md | operations/monitoring.md |
| stage-6/performance-analysis.md | performance.md |
| stage-3/ADR-*.md (or stage-*/ADR-*.md) | decisions/ADR-*.md |

## Mapping Rules

1. **One-to-one**: Direct copy with cleanup (remove exploration notes)
2. **Many-to-one**: Merge related files (L1+L2+L3 → single component doc)
3. **One-to-many**: Split by category (edge-cases → data-boundaries, timing, etc.)

## Source Location Notes

- **ADRs**: Typically in `stage-3/` but may appear in any stage. Scan all `stage-*/ADR-*.md` files.
- **Monitoring**: May be in `stage-6/monitoring*.md` or embedded in `operational-runbooks.md`. Extract if present.
- **Edge cases**: May be standalone `stage-6/edge-cases*.md` or embedded in component L3 docs. Extract from either location.

## Component Merging

For each component, merge progressive deepening:

```
stage-4/<component>-L1.md  ─┐
stage-5/<component>-L2.md  ─┼──► architecture/components/<component>.md
stage-6/<component>-L3.md  ─┘
```

**Naming flexibility**: Component files may use different patterns:
- `<component>-L1.md` (suffix style)
- `L1-<component>.md` (prefix style)
- `<component>.md` in `stage-4/L1/` subdirectory

Match on component name, not exact pattern.

## Edge Case Splitting

Split comprehensive edge case docs by category:

```
stage-6/edge-cases*.md ──► edge-cases/data-boundaries.md
                       ──► edge-cases/state-transitions.md
                       ──► edge-cases/timing.md
                       ──► edge-cases/integration.md
```
